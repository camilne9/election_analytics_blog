# In this R script I attempt to find a strong correlation between unemployment percentage
# (and in particular change in unemployment) on a state level and the the two party vote
# share of the incumbent in that state. Since I did not find a strong correlation using any
# attempted variant of the state level unemployment data, I conclude that it is unreasonable
# to create a model based on this variable and the data I have for it. Thus, my model focuses 
# on national economic data. This script shows attempts to find correlation involving state 
# level unemployment data. It can be completely disregarded, though I included it for reference. 

library(tidyverse)
library(ggplot2)
library(usmap)
library(ggthemes)
library(janitor)

setwd("~/gov1347/election_analytics_blog/scripts")

popvote_df <- read_csv("../data/popvote_1948-2016.csv")
pvstate_df <- read_csv("../data/popvote_bystate_1948-2016.csv")
economy_df <- read_csv("../data/econ.csv") 
popvote_df <- read_csv("../data/popvote_1948-2016.csv") 
local_econ_df <- read_csv("../data/local.csv")
electoral_college_df <- read_csv("../data/ec_1952-2020.csv")

fl_unemp <- local_econ_df %>% 
  clean_names() %>% 
  select(state_and_area, unemployed_prce, year, month) %>% 
  filter(month %in% c('01', '02', '03', '04', '05', '06', '07', '08', '09')) %>% 
  filter(year%%4 ==0) %>% 
  group_by(state_and_area, year) %>% 
  summarise(avg_unemp = mean(unemployed_prce)) %>% 
  ungroup() %>% 
  filter(state_and_area == "Florida")

unemp_state <- local_econ_df %>% 
  clean_names() %>% 
  select(state_and_area, unemployed_prce, year, month) %>% 
  filter(month == '10') %>% 
 # filter(month %in% c('01', '02', '03', '04', '05', '06', '07', '08', '09')) %>% 
  filter(year%%4 ==0) %>% 
  group_by(state_and_area, year) %>% 
 # summarise(avg_unemp = mean(unemployed_prce)) %>% 
  ungroup() %>% 
  mutate(state = state_and_area) %>% 
  select(-state_and_area)

republican_by_state <- pvstate_df %>% 
  select(state, year, R_pv2p)

model <- unemp_state %>% 
  right_join(republican_by_state, by = c('state', 'year'))

model %>% 
  filter(state == 'Massachusetts') %>% 
 # ggplot(aes(x = avg_unemp, y = R_pv2p))+
  ggplot(aes(x = unemployed_prce, y = R_pv2p))+
  geom_point()

shifted_once <- local_econ_df %>% 
  clean_names() %>% 
  select(state_and_area, unemployed_prce, year, month) %>% 
  mutate(year = year+1) %>% 
  mutate(prev_unemp = unemployed_prce) %>% 
  select(-unemployed_prce) %>% 
  filter(year%%4 ==0) %>% 
  filter(month == '10') %>% 
  mutate(state = state_and_area) %>% 
  select(-state_and_area, -month)

delt_unemp_state <- unemp_state %>% 
  right_join(shifted_once, by = c('state', 'year')) %>% 
  mutate(delta_unemp = unemployed_prce - prev_unemp) %>% 
  select(state, year, delta_unemp)

model_delta_unemp <- delt_unemp_state %>% 
  right_join(republican_by_state, by = c('state', 'year'))

model_delta_unemp %>% 
  filter(state == 'Maine') %>% 
  # ggplot(aes(x = avg_unemp, y = R_pv2p))+
  ggplot(aes(x = delta_unemp, y = R_pv2p))+
  geom_point()

#lets find the incumbent party vote share in each state for each year
model_inc_delta <- popvote_df %>% 
  filter(incumbent_party) %>% 
  select(year, party) %>% 
  right_join(model_delta_unemp, by = 'year') %>% 
  filter(!is.na(delta_unemp)) %>% 
  mutate(dem_inc = str_detect(party, "democrat")) %>% 
  mutate(inc_vote = abs(100*dem_inc-R_pv2p))

model_inc_delta %>% 
  filter(state == 'Texas') %>% 
  ggplot(aes(delta_unemp, y = inc_vote))+
  geom_point()

change_unemp_state <- local_econ_df %>% 
  clean_names() %>% 
  select(state_and_area, unemployed_prce, year, month) %>% 
  filter(month %in% c('05', '09')) %>% 
  pivot_wider(names_from = month, values_from = unemployed_prce) %>% 
  clean_names() %>% 
  mutate(change_unemp = x09-x05) %>% 
  filter(year%%4 ==0) %>% 
  mutate(state = state_and_area) %>% 
  select(-state_and_area, -x05, -x09)

same_year_model <- change_unemp_state %>% 
  right_join(model_inc_delta, by = c('year', 'state'))%>% 
 # filter(state != 'District of Columbia') %>% 
 # filter(state %in% c('Rhode Island', 'Massachusetts', 'Connecticut', 'New Hampshire', 'Vermont', 'Maine')) %>% 
  filter(dem_inc == FALSE)

same_year_model %>% 
 # filter(dem_inc == FALSE) %>% 
  #filter(state %in% c('California')) %>% 
  ggplot(aes(x = change_unemp, y = inc_vote, color = dem_inc))+
  geom_point()
  #facet_wrap(vars(state))

lm_econ <- lm(change_unemp ~ log(inc_vote), data = same_year_model)
summary(lm_econ)

#HEREHEREHEREHERE
baseline<- pvstate_df %>% 
  right_join(popvote_df, by = c('year')) %>% 
  select(state, year, R_pv2p, D_pv2p, incumbent_party, party) %>% 
  filter(year >=1976) %>% 
  filter(party == 'democrat') %>% 
  mutate(inc_vote = abs(100*incumbent_party - R_pv2p)) %>% 
  group_by(state, incumbent_party) %>% 
  summarize(baseline_inc = mean(inc_vote)) %>% 
  mutate(incumbent_party = str_replace(incumbent_party, 'TRUE', 'Democrat')) %>% 
  mutate(incumbent_party = str_replace(incumbent_party, 'FALSE', 'Republican')) %>% 
  pivot_wider(names_from = incumbent_party, values_from = baseline_inc)

incumbent_vote <- pvstate_df %>% 
  right_join(popvote_df, by = c('year')) %>% 
  select(state, year, R_pv2p, D_pv2p, incumbent_party, party) %>% 
  filter(year >=1976) %>% 
  filter(party == 'democrat') %>% 
  mutate(inc_vote = abs(100*incumbent_party - R_pv2p)) %>% 
  select(state, year, inc_vote)

incumbent_party <- popvote_df %>% 
  filter(incumbent_party) %>% 
  select(year, party) %>% 
  right_join(pvstate_df, by = 'year') %>% 
  filter(year >= 1976) %>% 
  select(-total, -R, -D)

#change_unemp_state needed too
final_model <- baseline %>% 
  right_join(change_unemp_state, by = 'state') %>% 
  left_join(incumbent_party, by = c('year', 'state')) %>% 
  filter(year != 2020) %>% 
  filter(state != 'New York city') %>% 
  filter(state != 'Los Angeles County') %>% 
  left_join(incumbent_vote, by = c('state', 'year')) %>% 
  mutate(rep_party = str_detect(party, 'republican')) %>%  
  select(state, Republican, Democrat, change_unemp, inc_vote, rep_party, party) %>% 
  mutate(delta = inc_vote - Republican*rep_party - Democrat*((rep_party+1)%%2)) %>% 
  filter(party == 'republican')

final_model %>% 
  #filter(state == 'New York') %>% 
  ggplot(aes(x = change_unemp, y = delta, color = party))+
  geom_point()

lm_econ <- lm(change_unemp ~ delta, data = final_model)
summary(lm_econ)
