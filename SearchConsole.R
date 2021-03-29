library(googleAuthR)
library(searchConsoleR)

email <- "user@gmail.com"

JSONfile <- '<client-id>.apps.googleusercontent.com.json'
gar_set_client(JSONfile)

gar_auth(email = email,
         scopes = 'https://www.googleapis.com/auth/webmasters.readonly')

SC_sites <- list_websites()

site <- SC_sites[which(grepl('domain', SC_sites$siteUrl)),]$siteUrl[2]

start_date <- as.Date("2020-01-01")
end_date <- as.Date("2020-12-31")

gbr_desktop_queries <- 
  search_analytics(site, 
                   start_date, end_date, 
                   c("query", "page"), 
                   dimensionFilterExp = c("device==DESKTOP"), 
                   searchType="web")

write.csv2(gbr_desktop_queries, file = "gbr_desktop_queries.csv")

#gbr_mobile_queries <- 
#  search_analytics(site, 
#                   "2020-01-01", "2020-12-31", 
#                   c("query", "page"), 
#                   dimensionFilterExp = c("device==MOBILE"), 
#                   searchType="web")

#write.csv2(gbr_mobile_queries, file = "gbr_mobile_queries.csv")

gar_deauth()
