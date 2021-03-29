library(dplyr)
library(lubridate)
library(urltools)
library(stringr)

#library("httr")
#library("tidyverse")

#library("xlsx")
#library("tibble")

dir <- paste(getwd(), '/Desktop/ContentAnalysis/csv', sep = '')

GA_PageData <- read.csv2(file = 'gaPageData.csv')
CR_Contents <- read.csv2(file = 'Contents.csv')
SC_Desktop_Queries <- read.csv2(file = 'gbr_desktop_queries.csv')
SC_Mobile_Queries <- read.csv2(file = 'gbr_mobile_queries.csv')

GA_PageData <- tibble(GA_PageData)
CR_Contents <- tibble(CR_Contents)
SC_Desktop_Queries <- tibble(SC_Desktop_Queries)
SC_Mobile_Queries <- tibble(SC_Mobile_Queries)

pageFilter <- paste("preview",
                    "search_keywords",
                    "wp-",
                    "login",
                    "page",
                    "null",
                    "iframe",
                    "s=",
                    "p=",
                    "post_type",
                    sep = "|")

cleangaPageData <- GA_PageData %>%
  filter(hostname == "domain.com",
         !str_detect(pagePath, pageFilter)) %>%
  mutate(bounceRate = round(bounceRate),
         avgPageLoadTime = round(avgPageLoadTime),
         ID = rownames(.)
         ) %>%
  select(ID, pagePath, pageTitle, sessions, bounceRate, pageviews, avgSessionDuration, avgPageLoadTime)

duplicateIDs <- cleangaPageData %>%
  group_by(pagePath) %>% 
  filter(n() > 1) %>%
  mutate(duplicate = ifelse(pageviews > mean(pageviews), FALSE, TRUE)) %>%
  filter(duplicate == TRUE) %>%
  ungroup() %>%
  select(ID)

notFound <- cleanedPageData %>%
  filter(grepl('Sayfa bulunamadı', pageTitle)) %>%
  select(ID)

cleanedPageData <- cleangaPageData %>%
  filter(!ID %in% c(duplicateIDs$ID, notFound$ID))

cleanedPageData %>%
  filter(sessions < mean(sessions)) %>%
  arrange(sessions)

CR_ContentsNew <- CR_Contents %>%
  mutate(pagePath = str_remove(Url, 'https://domain.com')) %>%
  select(-X, -Url) %>%
  tibble()

mergedData <- cleanedPageData %>% inner_join(CR_ContentsNew, by =  c("pagePath" = "pagePath"))
mergedData$Content_type <- as.factor(mergedData$Content_type)

mergedData[which(mergedData$sessions > 1000),]

summary(mergedData)
