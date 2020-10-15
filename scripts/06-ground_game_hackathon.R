library(tidyverse)
library(lubridate)
library(zoo)
library(ggthemes)
library(knitr)
library(stargazer)
library(janitor)
library(usmap)

setwd("~/gov1347/election_analytics_blog/scripts")

fo_dem_12_16 <- read_csv("../data/fieldoffice_2012-2016_byaddress.csv")

fo_dem_12_16 %>% 
  group_by(candidate) %>% 
  summarize(field_offices = n())

fo_dem_12_16 %>%
  group_by(state) %>%
  summarize(field_offices = n()) %>% 
  arrange(desc(field_offices))

fo_dem_12_16 %>% 
  filter(candidate == "Obama") %>% 
  mutate(total = n()) %>% 
  filter(state == "WI") %>% 
  mutate(wi_total = n()) %>% 
  mutate(proportion = wi_total/total) %>% 
  group_by(city) %>% 
  summarize(count = n(), total = mean(total), wi_total = mean(wi_total), 
            percentage = 100*mean(proportion)) %>% 
  arrange(desc(count))

fo_dem_12_16 %>% 
  filter(candidate == "Clinton") %>% 
  mutate(total = n()) %>% 
  filter(state == "WI") %>% 
  mutate(wi_total = n()) %>% 
  mutate(proportion = wi_total/total) %>% 
  group_by(city) %>% 
  summarize(count = n(), total = mean(total), wi_total = mean(wi_total), 
            percentage = 100*mean(proportion)) %>% 
  arrange(desc(count))

