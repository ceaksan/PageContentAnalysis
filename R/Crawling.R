packages <- c("Rcrawler","dplyr", "stringr")

if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

library(Rcrawler)
library(dplyr)
library(stringr)

parallel:::setDefaultClusterOptions(setup_strategy = "sequential")

CustomXPaths <- c("//link[@rel='canonical']/@href",
                  "//meta[@name='robots']/@content",
                  "//meta[@name='description']/@content",
                  "//title",
                  "//h1",
                  "//div[@class='entry-content']"
)

CustomLabels <- c("link_canonical",
                  "meta_robots",
                  "meta_description",
                  "title",
                  "h1",
                  "content"
)

setwd("~/Desktop")

Rcrawler(Website = "https://domain.com/",
         ExtractXpathPat = CustomXPaths, 
         PatternsNames = CustomLabels)

saveRDS(DATA, file="DATA.rds")
saveRDS(INDEX, file="INDEX.rds")

mergedCrawl <- cbind(INDEX, data.frame(do.call(rbind, DATA)))

mergedCrawl$Id <- as.integer(mergedCrawl$Id)

Indexable_pages <- mergedCrawl %>%
  mutate(Canonical_Indexability = ifelse(Url == link_canonical | is.na(mergedCrawl$link_canonical), TRUE, FALSE)) %>%
  mutate(Indexation = ifelse(grepl("NOINDEX|noindex", mergedCrawl$meta_robots), FALSE, TRUE)) %>%
  filter(Canonical_Indexability == TRUE & Indexation == TRUE)

PageData <- Indexable_pages %>%
  filter(`Http Resp` == '200' & `Content Type` == 'text/html') %>%
  mutate(Content_type =
           ifelse(str_detect(Indexable_pages$Url, "/kategori|etiket|urun-etiketi|kahve-hakkinda-her-sey/"), "Taxonomy",
                  ifelse(str_detect(Indexable_pages$Url, "/liste|listings|listing-dashboard/"), "Listing",
                         ifelse(str_detect(Indexable_pages$Url, "/magaza|iletisim|submit-a-post/"), "Pages",
                                ifelse(str_detect(Indexable_pages$Url, "/mekan"), "Places",
                                       ifelse(str_detect(Indexable_pages$Url, "/urun"), "Products", "Posts")))))) %>%
  select(Url, meta_description, title, h1, content, Content_type) %>%
  group_by(Content_type) %>%
  unique() %>%
  arrange(Content_type)

PageData$Content_type <- as.factor(PageData$Content_type)
PageData$meta_description <- as.character(PageData$meta_description)
PageData$title <- as.character(PageData$title)
PageData$h1 <- as.character(PageData$h1)
PageData$content <- as.list(PageData$content)
PageData$Content_type <- as.character(PageData$Content_type)

PageData %>%
  group_by(Content_type) %>%
  summarise(no_rows = n())

PageData %>%
  filter(Content_type == 'Posts') %>%
  mutate(content = trimws(as.character(content))) %>%
  write.csv2(., file = "Contents.csv")

