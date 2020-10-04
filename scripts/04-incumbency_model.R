library(tidyverse)
library(lubridate)
library(zoo)
library(ggthemes)
library(knitr)
library(stargazer)

setwd("~/gov1347/election_analytics_blog/scripts")

pop_vote <- read_csv("../data/popvote_1948-2016.csv") 
state_vote <- read_csv("../data/popvote_bystate_1948-2016.csv")
fedgrants_county_df <- read_csv("../data/fedgrants_bycounty_1988-2008.csv")
fedgrants_state_df <- read_csv("../data/fedgrants_bystate_1988-2008.csv")

pop_vote %>% 
  filter(incumbent == TRUE) %>% 
  summarize(avg_pv = mean(pv2p))

grant_increase <- fedgrants_state_df %>% 
  filter(elxn_year == 1) %>% 
  group_by(state_abb) %>% 
  mutate(prev_grant = lag(grant_mil, order_by = year)) %>% 
  mutate(grant_increase = grant_mil - prev_grant) %>% 
  ungroup()

full_popvote <- pop_vote %>% 
  left_join(state_vote, by = c("year")) %>% 
  mutate(state_abb = setNames(state.abb, state.name)[state]) %>% 
  right_join(grant_increase, by = c('state_abb', 'year')) %>% 
  mutate(swing_state = str_detect(state_year_type, "swing")) %>% 
  replace_na(list(swing_state = FALSE)) %>% 
  filter(party == 'republican') %>% 
  group_by(state) %>% 
  mutate(prev_dem_vote = lag(D_pv2p, order_by = year)) %>% 
  mutate(prev_rep_vote = lag(R_pv2p, order_by = year)) %>% 
  ungroup()

selected_data <- full_popvote %>% 
  mutate(dem_increase = D_pv2p - prev_dem_vote) %>% 
  mutate(rep_increase = R_pv2p - prev_rep_vote) %>% 
  select(year, party, incumbent, incumbent_party, state, 
         grant_increase, swing_state, rep_increase, dem_increase) %>% 
  filter(year > 1984) %>% 
  mutate(incumbent_increase = incumbent_party*rep_increase + (1-incumbent_party)*dem_increase)

selected_data %>% 
  ggplot(aes(x = grant_increase, y = incumbent_increase))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)

selected_data %>% 
  ggplot(aes(x = grant_increase, y = incumbent_increase, color = incumbent))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)

selected_data %>% 
  ggplot(aes(x = grant_increase, y = incumbent_increase, color = incumbent_party))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)

selected_data %>% 
  ggplot(aes(x = grant_increase, y = incumbent_increase, color = swing_state))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)
