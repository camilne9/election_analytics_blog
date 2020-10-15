library(tidyverse)
library(lubridate)
library(zoo)
library(ggthemes)
library(knitr)
library(stargazer)
library(janitor)
library(usmap)

setwd("~/gov1347/election_analytics_blog/scripts")

# First I read in the relevant data
pop_vote <- read_csv("../data/popvote_1948-2016.csv") 
state_vote <- read_csv("../data/popvote_bystate_1948-2016.csv")
fedgrants_county_df <- read_csv("../data/fedgrants_bycounty_1988-2008.csv")
fedgrants_state_df <- read_csv("../data/fedgrants_bystate_1988-2008.csv")
ad_campaigns <- read_csv("../data/ad_campaigns_2000-2012.csv")
ad_creative <- read_csv("../data/ad_creative_2000-2012.csv")
ads_2020 <- read_csv("../data/ads_2020.csv")
battleground <- read_csv("../data/battleground.csv")
romney <- read_csv("../data/RomneyGroundGame2012.csv")

romney %>% 
  filter(state != "nationwide") %>%
  ggplot(aes(x = field.offices, y = contacts))+
  geom_point()

romney %>% 
  filter(state != "nationwide") %>% 
  summarize(phone = sum(Phone), mail = sum(Mail), door = sum(Door))

romney %>% 
  filter(state != "nationwide") %>% 
  filter(contacts != 0) %>% 
  mutate(phone_max = ifelse(Phone > (Mail + Door), TRUE, FALSE)) %>% 
  filter(phone_max == FALSE)

