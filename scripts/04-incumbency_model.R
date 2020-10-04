library(tidyverse)
library(lubridate)
library(zoo)
library(ggthemes)
library(knitr)
library(stargazer)

setwd("~/gov1347/election_analytics_blog/scripts")

# First I read in the relevant data
pop_vote <- read_csv("../data/popvote_1948-2016.csv") 
state_vote <- read_csv("../data/popvote_bystate_1948-2016.csv")
fedgrants_county_df <- read_csv("../data/fedgrants_bycounty_1988-2008.csv")
fedgrants_state_df <- read_csv("../data/fedgrants_bystate_1988-2008.csv")

# I want to find the increase in federal grants in each state between each election
# so I compare the grant amount to the previous grant amount.
grant_increase <- fedgrants_state_df %>% 
  filter(elxn_year == 1) %>% 
  group_by(state_abb) %>% 
  mutate(prev_grant = lag(grant_mil, order_by = year)) %>% 
  mutate(grant_increase = grant_mil - prev_grant) %>% 
  ungroup()

# I combine all the data to look at national results (including incumbency), 
# state specific results, and grants data. I make columns of the previous
# pop vote in each state so we can compare CHANGE in popular vote
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

# I find the change in popular vote between elections for each state, and find 
# what change applied for the incumbent party specifically.
selected_data <- full_popvote %>% 
  mutate(dem_increase = D_pv2p - prev_dem_vote) %>% 
  mutate(rep_increase = R_pv2p - prev_rep_vote) %>% 
  select(year, party, incumbent, incumbent_party, state, 
         grant_increase, swing_state, rep_increase, dem_increase) %>% 
  filter(year > 1984) %>% 
  mutate(incumbent_increase = incumbent_party*rep_increase + (1-incumbent_party)*dem_increase)
# =========================
# =========================
# The below code is still unacceptable 
incumbent_case <- pop_vote %>% 
  left_join(state_vote, by = c("year")) %>% 
  mutate(state_abb = setNames(state.abb, state.name)[state]) %>% 
  right_join(grant_increase, by = c('state_abb', 'year')) %>% 
  mutate(swing_state = str_detect(state_year_type, "swing")) %>% 
  replace_na(list(swing_state = FALSE)) %>% 
  filter(incumbent) %>% 
  group_by(state) %>% 
  mutate(prev_dem_vote = lag(D_pv2p, order_by = year)) %>% 
  mutate(prev_rep_vote = lag(R_pv2p, order_by = year)) %>% 
  ungroup()

incumbent_data <- incumbent_case %>% 
  mutate(dem_increase = D_pv2p - prev_dem_vote) %>% 
  mutate(rep_increase = R_pv2p - prev_rep_vote) %>% 
  select(year, party, incumbent, incumbent_party, state, 
         grant_increase, swing_state, rep_increase, dem_increase) %>% 
  filter(year > 1984) %>% 
  mutate(incumbent_increase = str_detect(party, "republican")*rep_increase + 
           (1-str_detect(party, "republican"))*dem_increase)
# =========================
# =========================

# I make plots of the overall trend, the trend broken down by swing and non-swing,
# and the trend broken down by party.
selected_data %>% 
  ggplot(aes(x = grant_increase, y = incumbent_increase))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)

# incumbent_data %>% 
#   ggplot(aes(x = grant_increase, y = incumbent_increase, color = party))+
#   geom_point()+
#   geom_smooth(method = 'lm', se = 0)

selected_data %>% 
  ggplot(aes(x = grant_increase, y = incumbent_increase, color = incumbent_party))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)

selected_data %>% 
  ggplot(aes(x = grant_increase, y = incumbent_increase, color = swing_state))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)

# Now I explicitly find the linear regression of each of the relevant cases
swing_state <- selected_data %>% 
  filter(swing_state)
lm_swing <- lm(incumbent_increase ~ grant_increase, data = swing_state)
summary(lm_swing)

non_swing_state <- selected_data %>% 
  filter(swing_state == FALSE)
lm_nonswing <- lm(incumbent_increase ~ grant_increase, data = non_swing_state)
summary(lm_nonswing)

republican_incumbent <- selected_data %>% 
  filter(incumbent)
lm_republican_incumbent <- lm(incumbent_increase ~ grant_increase, data = republican_incumbent)
summary(lm_republican_incumbent)

democrat_incumbent <- selected_data %>% 
  filter(incumbent == FALSE)
lm_democrat_incumbent <- lm(incumbent_increase ~ grant_increase, data = democrat_incumbent)
summary(lm_democrat_incumbent)

# reelection_republican <- incumbent_data %>% 
#   filter(party == "republican")
# lm_reelection_republican <- lm(incumbent_increase ~ grant_increase, data = reelection_republican)
# summary(lm_reelection_republican)
# 
# reelection_democrat <- incumbent_data %>% 
#   filter(party == "democrat")
# lm_reelection_democrat <- lm(incumbent_increase ~ grant_increase, data = reelection_democrat)
# summary(lm_reelection_democrat)
