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

swing_states <- fedgrants_state_df %>% 
  filter(elxn_year == 1) %>% 
  mutate(swing_state = str_detect(state_year_type, "swing")) %>% 
  replace_na(list(swing_state = FALSE)) %>% 
  mutate(state = state_abb) %>% 
  select(year, state, swing_state)

ad_spending <- ad_campaigns %>% 
  mutate(month = month(air_date)) %>% 
  filter(month == 9) %>% 
  group_by(party, state, cycle) %>% 
  summarize(expenses = sum(total_cost)) %>% 
  ungroup() %>% 
  pivot_wider(names_from = party, values_from = expenses) %>% 
  mutate(year = cycle) %>% 
  select(-cycle) %>% 
  left_join(swing_states, by = c('state', 'year')) %>% 
  filter(!is.na(swing_state))

state_vote %>% 
  mutate(winner = ifelse(D>R, "Democrat", "Republican")) %>%
  mutate(state = setNames(state.abb, state.name)[state]) %>% 
  select(-total, -D, -R) %>% 
  right_join(ad_spending, by = c('state', 'year')) %>% 
  filter(!is.na(democrat)) %>% 
  filter(!is.na(republican)) %>% 
  mutate(lean = ifelse(swing_state == FALSE, winner, "swing")) %>% 
  mutate(rep_funding_edge = republican - democrat) %>% 
  filter(lean == "Democrat") %>% 
  ggplot(aes(x = rep_funding_edge, y = R_pv2p, color = lean))+
  geom_point()+
  geom_smooth(method = "glm", 
              se = FALSE) 

