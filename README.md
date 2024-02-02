# Scrape-an-Online-Parking-Booking-Platform-With-R
_Web scrape a book parking comparison website for a data-driven pricing strategy in the travel/tourism industry_

## Business Understanding

The company is involved in the airport parking service and needs to appear in a price comparison platform for users who want to book a park near the airport and reach the terminals by shuttle bus.

Considering every company appears on multiple platforms with different prices, the current firm needs to estimate the prices for the chosen website to be shown in high positions.

Building a dataset manually by gathering the data from the comparison site page result for each day of a month and every competitor is inefficient. So, we will use web scraping for this purpose.

## Data Understanding

The data needed are in HTML format and vary by calendar season, so, for example, prices during season holidays are quite different from the ones during the off-peak season.
So, to gather prices efficiently, the company needs to scrape data from the web and undertake this procedure more than once a year.

Diving deeper into the terms and conditions page of the comparison website, We found no prohibition about web scraping. Moreover, the data involved do not comprehend sensitive personal information. Lastly, to keep the frequency of the requests at a minimum, we will observe a 15-second delay between each request iteration.

The website already implemented an API service but only involves unavailable parking services. So, we go for client-side web scraping using Remote Selenium Web Driver, a Docker container to run RStudio and Selenium, and the RSelenium R package.

Here are the [Docker Compose file](https://github.com/EdoardoMonteleoni/Booking-Platform-Web-Scraping/blob/main/docker-compose.yml) and the complete [R code.](https://github.com/EdoardoMonteleoni/Booking-Platform-Web-Scraping/blob/main/Code.R)

## Data Preparation

The second part of the code is about cleaning and preparing the data.
The company needs an order of magnitude of the prices that appear on top of the page results and other central tendency and variation measures. 

[Table1.csv](https://github.com/EdoardoMonteleoni/Booking-Platform-Web-Scraping/blob/main/Table1.csv) focuses exclusively on the companies appearing on top, their star reviews and the distance from the airport, other than the applied price. This table is also helpful for future competitive analyses.

The second table [Table2.csv](https://github.com/EdoardoMonteleoni/Booking-Platform-Web-Scraping/blob/main/Table2.csv) gives a broader look at price ranges, which helps build a robust price strategy involving factors within the company. Also, by focusing on the last column, "2nd_pos_price", one can evaluate the efficiency of the applied price strategy. To gain a higher position in the page results, it would be enough to keep the price just one euro cent lower than the target competitor; in contrast, a big gap between the first two positions can reveal inefficiencies.


## Exploratory Data Analysis

Considering the company's primary purpose is to appear in front of as many web users as possible, the competitor prices derived in this project, weighted  with the desired profit margin, could give a good starting point for a pricing strategy.

As already touched on, [Table2.csv](https://github.com/EdoardoMonteleoni/Booking-Platform-Web-Scraping/blob/main/Table2.csv) shows some measures of central tendency and one measure of variability, useful to gauge the frequency distribution of the prices grouped by days of permanence.

![Table2_jpeg](https://github.com/EdoardoMonteleoni/Online-Booking-Website-Scraping/assets/105068746/7ed0c6f9-e2dc-4db2-a905-ae659fdba86b)

If we want to analyse competitor prices, for example, for two days of staying (the minimum accepted by our company), we see that the minimum price applied is € 33.00, which ranks first in the page results. We see that (1D) 10% of the prices are below € 36.00 and (Q1) 25% are below € 38.00. The median is around € 43.00, whereas 75% and 90% of the prices are below € 46.00 and € 49.00, respectively. 

The second-last column of "Table2" represents the Inter-Decile Range, the difference between the ninth and the first decile. This measure is rather robust as it is not influenced by 20% of extreme values of the distribution. This index shows that, for short stays, prices vary relatively less compared to longer permanences, meaning that - in this comparison website and for the date range set - people might book short-stay parking services more frequently. Hence, different pricing strategies for the two segments. 

The last column, "2nd_pos_price (€)", shows the price applied by the company ranked second in the page results. Measuring the range between the two prices could be useful if the chosen strategy is to target the second position efficiently. For example, looking at the first row, we could set up a price of around € 35.80. 

## Conclusions

Competitor price analyses could become overwhelming and error-prone, particularly for companies in the hospitality sector that rely on comparison websites as a primary customer acquisition strategy. Web scraping can facilitate and automate the data collection phase, especially when new actors often enter the market, or prices must be frequently adjusted based on seasonal demand.

By analysing the data in "Table1" the company can evaluate the competitor features and the service offered by the local firm that ranked first on the website, data such as the distance from the airport, the star rate, the number of reviews and the price for each day of permanence. Moreover, by looking at the summary statistics shown in "Table2", the company can evaluate whether a price target corresponding to the second position on page results could be an efficient pricing strategy for this acquisition channel.
