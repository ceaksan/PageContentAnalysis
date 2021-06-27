library(googleAuthR)
library(googleAnalyticsR)

email <- "user@gmail.com"
site <- "https://domain.com"

JSONfile <- '<client-id>.apps.googleusercontent.com.json'
gar_set_client(JSONfile)

gar_auth(email = email,
         scopes = 'https://www.googleapis.com/auth/analytics.readonly')

GA_accounts <- ga_account_list()

selectedGA <- GA_accounts[which(grepl('domain.com', GA_accounts$websiteUrl)),]
getIDs <- ifelse(any(selectedGA$starred == "TRUE"),
                 selectedGA[which(selectedGA$starred == "TRUE"),]$viewId,
                 selectedGA$viewId[1])
GA_id <- ifelse((!is.na(getIDs) && length(getIDs) == 1 &&
                   typeof(getIDs) == 'character'),
                paste('ga:', getIDs, sep = ''),
                stop("error message"))

start_date <- as.Date("2020-01-01")
end_date <- as.Date("2020-12-31")

#last_day_prev_year <- function(x) floor_date(x, "year") - days(1)
#last_day_prev_year(Sys.Date())-ddays(364)

gaPageData <- google_analytics(
  GA_id,
  date_range = c(start_date, end_date),
  metrics = c("ga:sessions",
              "ga:bounceRate",
              "ga:pageviews",
              "ga:avgSessionDuration",
              "ga:avgPageLoadTime"),
  dimensions = c("ga:hostname",
                 "ga:pagePath",
                 "ga:pageTitle"),
  anti_sample =  TRUE,
  anti_sample_batches = 30,
  segments = segment_ga4(name = "Organic Traffic",
                         segment_id = "gaid::-5"),
  max = -1)

gar_deauth()

gaPageData <- tibble(gaPageData)

write.csv2(gaPageData, file = "gaPageData.csv") 
