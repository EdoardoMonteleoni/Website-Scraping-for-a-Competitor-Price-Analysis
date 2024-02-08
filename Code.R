# Import libraries

library(tibble)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(tsibble)
library(tsibbledata)
library(feasts)
library(fable)
library(fabletools)

# Data set URL: https://www.adr.it/web/aeroporti-di-roma-en/bsn-traffic-data
# import CSV file
# Type your directory path along with the CSV file name in "~/..your_path/filename.csv"

search_pass <- read.csv("~/Documents/R-projects/Google Ads/googleads_search_volume.csv", fileEncoding = "UTF-8")

# Create a Tsibble object (time series tibble object) modifying the variable 
# named "yearmonth" of type: yearmonth(), using the nested function lubridate::my()
# since the original format is of type: "mm-YYYY"
# I will set "yearmonth" as the required index.

# Since January 2018 is the first raw, the corresponding variation for these 
# records will have na's, which can cause issues when applying modelling, I will 
# cut off the entire raw

# "ts" stands for time series

gads_ts <- search_pass |> 
  mutate(date = yearmonth(my(yearmonth))) |> 
  filter(!is.na(Var_search)) |> 
  as_tsibble(index = date) |> 
  relocate(date, 1) |> 
  select(-yearmonth, -Search.Volume, -Num_passengers)

# Inspect % Search Volume variation against % passengers in the time frame

plot_ts <- gads_ts |> 
  pivot_longer(c(Var_search, Var_pass), names_to = "Series") |> 
  autoplot(value) +
  labs(y = "Δ %",
       title = "Δ % passengers and Δ % Google Ads Search Volume Years 2018-2022")

plot_ts

# Inspect seasonality

ts_seasons <- gads_ts |> 
  gg_season(Var_search, labels = "both") +
  labs(y = "Google Ads % Search Volume (#000)",
       title = "Seasonal plot: Montly % Search Volume variation from Jan 2018 to Dec 2022")
ts_seasons

# Seasonal sub-series

ts_subseries <- gads_ts |> 
  gg_subseries(Var_search)
ts_subseries

# Check for the linear relationship between Search Volume variation and Passengers
# variation (month over month)

reg_rel <- gads_ts |> 
  ggplot(aes(Var_pass, Var_search)) +
  labs(x = "Number of passengers variation over time", y = "Search Volume variation over time", 
       title = "Δ % of passengers vs Google Ads Search Volume (MoM - 2018-2022)") +
  geom_point()+
  geom_smooth(method = "lm", se = FALSE)

# Decomposing the time series by the STL method (*)

gads_dec <- gads_ts |> 
  model(stl = STL(Var_search))

components(gads_dec) |> 
  autoplot()

# Create a training and a testing data set to test the models

train_search <- gads_ts |> 
  slice(1:47)

test_search <- gads_ts |> 
  slice(48:60)

# Derive:
      # 1- a (fit1) linear regression model for time series built using 
      # the dependent variable Google Ads Search Volume (Δ%) 
      # weighed with "passengers (Δ%)" as additive regressor.
      
      # 2 - a (fit2) linear regression model for time series made up of 
      # the dependent variable Google Ads Search Volume (Δ), using trend and 
      # season as dummy variables.

      # 3 - a final (fit3) Exponential Smoothing model using the Holt-Winters’ method
      # with additive trend and seasonal components.

fit <- train_search |> 
      model(tslm1 = TSLM(Var_search ~ Var_pass + trend() + season()),
            tslm2 = TSLM(Var_search ~ trend() + season()),
            ets = ETS(Var_search ~ error("A") + trend("A") + season("A"))) # model

# Measure the predictive accuracy of regressor for each model

reg_assess <- glance(fit) |> 
  select(adj_r_squared, AIC, BIC, CV)

# Evaluate the models

fit1_eval <- gg_tsresiduals(fit1)
fit2_eval <- gg_tsresiduals(fit2)
fit3_eval <- gg_tsresiduals(fit3)



# Producing forecasts from the "fit" object adding the "test" data frame

fc_total <- fit |>
   forecast(new_data = test_search)


# Plot the forecast over the testing period data frame

gads_ts |> 
           autoplot(Var_search) +
           autolayer(fc_total, level = NULL)

fit_search <- gads_ts |> 
       model(TSLM(
           Var_search ~ Var_pass + trend() + season())) # model

# Create 

snaive_pass_fc <- gads_ts |> 
     model(SNAIVE(Var_pass))

fc_naive <- snaive_pass_fc |>
forecast(h = "3 months")


# Create two scenarios with the historical average variation of passengers 
# volume and one scenario where the forecasted value of passenger volume 
# is derived using the seasonal naive model

new_trend <- scenarios (
  "pass_avg" = new_data(gads_ts, 3) |> 
    mutate(Var_pass = mean(gads_ts$Var_pass)),
  "pass_snaive" = new_data(gads_ts, 3) |> 
    mutate(Var_pass = fc_naive$.mean)) # scenarios

# Forecast the variations

fcast <- forecast(fit_search, new_trend)

# Plot the time series search volume variation forecast

gads_ts |> 
       autoplot(Var_search) +
       autolayer(fcast, level = NULL) +
       labs(title = "3 months variation forecast", y = "Δ % change")

# Create a tibble data frame with three months forecast search volume variation

var_forecast <- tibble(date = fcast$date, scenario = fcast$.scenario, 
                       "search_volume_fc (Δ %)" = fcast$.mean)

# (*) Hyndman, R.J., & Athanasopoulos, G. (2021) Forecasting: principles 
# and practice, 3rd edition, OTexts: Melbourne, Australia. OTexts.com/fpp3.
# Accessed on 2024-02-05.


