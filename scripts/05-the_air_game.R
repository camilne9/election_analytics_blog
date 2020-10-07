# 05-the air game
#in class work:

library(tidyverse)
library(lubridate)
library(zoo)
library(ggthemes)
library(knitr)
library(stargazer)
library(janitor)

setwd("~/gov1347/election_analytics_blog/scripts")

# First I read in the relevant data
pop_vote <- read_csv("../data/popvote_1948-2016.csv") 
state_vote <- read_csv("../data/popvote_bystate_1948-2016.csv")
fedgrants_county_df <- read_csv("../data/fedgrants_bycounty_1988-2008.csv")
fedgrants_state_df <- read_csv("../data/fedgrants_bystate_1988-2008.csv")
ad_campaigns <- read_csv("../data/ad_campaigns_2000-2012.csv")
ad_creative <- read_csv("../data/ad_creative_2000-2012.csv")
ads_2020 <- read_csv("../data/ads_2020.csv")

obama08 <- ad_campaigns %>% 
  clean_names() %>% 
  filter(sponsor == "Barack Obama") %>% 
  mutate(year = year(air_date)) %>% 
  filter(year <= 2008) %>% 
  group_by(state) %>% 
  summarize(cost = sum(total_cost))

winner <- state_vote %>% 
  filter(year == 2008) %>% 
  mutate(win = (D_pv2p > R_pv2p)) %>% 
  mutate(state = setNames(state.abb, state.name)[state]) %>% 
  select(state, win)

obama08 %>% 
  left_join(winner, by = 'state') %>% 
  filter(state %in% c("MI", 'AZ', 'FL', 'MN', 'CO', 'PA', 
                      'VA', 'IN', 'NV', 'NC', 'WI', 'NH', 'MO', 'OH', 'IA')) %>%
  arrange(cost) %>% 
  ggplot(aes(x = reorder(state, -cost), y = cost/10^6, fill = win))+
  geom_col()+
  labs(x = "State", y = "Money Spent on Ads (Millions of $)", 
       title = "Obama's Spending in Swing States")
