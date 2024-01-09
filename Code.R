# Libraries

library(RSelenium)
library(rvest)
library(purrr)
library(dplyr)
library(stringr)
library(tidyverse)

# Initiate a new remote driver and connect to the remote Selenium server

remDr <- remoteDriver(
  remoteServerAddr = "selenium",
  port = 4444
)
remDr$open()

# define the base URL

base_url <- "https://www.parkvia.com/en-GB/book/results?producttype=P&location=MXP&startdate="

# define the object "tomorrow" for setting the first day of the query

tomorrow <- Sys.Date() + 1

# define the time part of the URL, which is fixed for the purposes of this work

url_time <- "&starttime=11:00&endtime=22:00"

# define a vector with numbers from 1 to 31 to compute the days for the URLs

days <- c(1:30)

# define the object "enddate" containing dates in proper format from 
# tomorrow day and throughout the following 30 days.

enddate <- mapply(function(a, b) a + b, tomorrow, days)

# convert the vector from double to date format "%d/%m/%Y"

enddate <- as.Date(enddate, origin = "1970-01-01")

# clean the fold "download/"

unlink("~/rstudio/parkvia/download/*")

# Since I do not want to return any value but iterate through each value in the
# object "enddate", I use purrr::walk function to save the html files so that
# I can scrape them afterwards. Original code from Mikkel Freltoft Krogsholm.

walk(enddate, function(dates){
  
  file_day <- str_extract(dates, "\\d\\w+$")
  
  # define the URL for each "enddate" date contained in the object  
  url_page <- str_glue("{base_url}{tomorrow}&enddate={dates}{url_time}")
  
  message(str_glue("\nFetching: {url_page}"))
          
  remDr$navigate(url_page)
  
  Sys.sleep(15)
  
  html_raw <- remDr$getPageSource()[[1]]
  
  # The fold "download/" is intended to be already created in the work directory
  
  html_file <- paste0("~/rstudio/parkvia/download/", file_day,".html")
  
  write_file(html_raw, html_file)
})

# Close the session

remDr$close()

###### Loop over each HTML file to scrape data ################################

Sys.sleep(10)

html_files <- list.files("download/") %>% 
  paste0("download/",.)

all_parks <- map_dfr(html_files, function(html_file){
  
  html_data <- read_html(html_file)

  # extract the page element results except the ones grouped in the
  # "not_available" CSS class
  
  parking_results <- html_data |> 
    html_element("#opresults") |> 
    html_elements(":not(not_available)") |> 
    html_elements(".card")
  
  # extract check-in and check-out day from the web page and compute the length of stay
  
  day_in <- html_data %>% 
    html_element("#dateFrom") %>% 
    html_text()
  
  day_out <- html_data %>% 
    html_element("#dateTo") %>% 
    html_text()
  
  n_days <- unclass(as.Date(day_out, "%d/%m/%Y")) - 
            unclass(as.Date(day_in, "%d/%m/%Y"))
  
  # Custom function for iterating the extraction of each parking detail 
  # to compose a tibble data frame for each day of permanence
  
  fun_park <- function(single_result) {
    
    park_name <- single_result |> 
      html_element(".op_head") |> 
      html_text(trim = TRUE)
    
    details <- single_result |>
      html_element(".card-body")
    
    stars <- single_result |> 
      html_element(".stars") |> 
      html_text(trim = TRUE)
    
    num_of_reviews <- single_result |> 
      html_element(".reviewslink") |> 
      html_text(trim = TRUE)
    
    first_price <- details |> 
      html_element(".price") |> 
      html_text(trim = TRUE)
    
    discount <- details |> 
      html_element(".inner.d-inline") |> 
      html_text(trim = TRUE)
    
    total_price <- single_result |> 
      html_element(".w-auto.price") |> 
      html_text(trim = TRUE)
    
    distance <- single_result %>% 
      html_element(".distance") %>% 
      html_text(trim = TRUE)
    
    more_info <- single_result %>% 
      html_element(".features")
    
    # create the data frame
    
    tibble(n_days, park_name, stars, num_of_reviews, first_price, discount, 
           total_price, distance)
    
  } # fun_park
  
  # For each "parking result", create a data frame by row-binding the tibble 
  # above for each "parking_results" content by the purrr::map_dfr function
  
  map_dfr(parking_results, fun_park)
  
}) # all_parks

#### Clean and build the final data frames ####################################

Sys.sleep(10)

# clean the tibble data frame and transform the price variable

all_parks_cleaned <- all_park %>% 
  group_by(n_days) %>% 
  filter(first_price != "Not Available") %>% 
  mutate(price = as.numeric(str_extract(total_price, "\\d.+"))) %>% 
  select(-first_price, -total_price) %>% 
  arrange(n_days, price)

# create a tibble data frame with the minimum price for each day.
# Since equal minimum prices are shown as multiple values, I will use
# the dplyr::slice_head function to pick the first value

all_parks_min <- all_parks_cleaned %>% 
  group_by(n_days) %>% 
  slice_min(price) %>% 
  slice_head()

# write a CSV file

write.csv(all_parks_min, "~/path.../parkvia_min.csv", fileEncoding = "UTF-8")

# create a summary tibble data frame

all_parks_sum <- all_parks_cleaned %>%
  group_by(n_days) %>% 
  summarise(
            "min_price (€)" = min(price, na.rm = TRUE),
            "D1 (€)" = quantile(price, probs = 0.10, na.rm = TRUE),
            "Q1 (€)" = round(quantile(price, probs = 0.25, na.rm = TRUE),2),
            "median_price (€)" = round(median(price, na.rm = TRUE), 2),
            "Q3 (€)" = round(quantile(price, probs = 0.75, na.rm = TRUE),2),
            "D9 (€)" = quantile(price, probs = 0.90, na.rm = TRUE),
            "max_price (€)" = max(price, na.rm = TRUE),
            "IDR" = quantile(price, probs = 0.90, na.rm = TRUE) -
                    quantile(price, probs = 0.10, na.rm = TRUE)
              ) # summarise

# To have a clearer picture, a useful column to add to the summary data frame
# is the value related to the second less expensive price.
# Since there are repeated rows, I will proceed to create a simple data frame
# and then add the column "2nd_pos_price" to the summary data frame above

sec_pos <- all_parks_cleaned %>% 
  group_by(n_days) %>% 
  slice_head(n = 2) %>% 
  slice_head() %>% 
  select(n_days, price)

# Then I add the "2nd_pos_price" column in a new tibble data frame

price_summary <- tibble(all_parks_sum, "2nd_pos_price" = sec_pos$price)

# write the summary CSV file

write.csv(price_summary, "~/path.../price_summary.csv", fileEncoding = "UTF-8")
