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
turnout <- read_csv("../data/turnout_1980-2016.csv")
demographics <- read_csv("../data/demographic_1990-2018.csv")
popvote_bycounty_2012_2016_WI <- read_csv("../data/popvote_bycounty_2012-2016_WI.csv")
local <- read_csv("../data/local.csv")

state_vote %>% 
  mutate(state = setNames(state.abb, state.name)[state]) %>% 
  left_join(demographics, by = c('state', 'year')) %>% 
  # select(state, year, D_pv2p, Black) %>% 
  # filter(!is.na(White)) %>% 
  ggplot(aes(x = Black, y = D_pv2p))+
  geom_point()
  
state_turnout <- turnout %>%
  filter(state != "United States") %>% 
  left_join(state_vote, group_by = c('state', 'year')) %>% 
  filter(year %%4 == 0) %>% 
  mutate(dem_win = (R_pv2p < D_pv2p)) %>% 
  filter(abs(R_pv2p-D_pv2p) < 8) %>% 
  mutate(turnout_pct = as.numeric(sub("%", "", turnout_pct))) %>% 
  mutate(turnout_pct = ifelse(year == 2016, turnout_pct*100, turnout_pct))

state_turnout %>% 
  # filter(dem_win) %>% 
  ggplot(aes(turnout_pct))+
  geom_histogram(bins = 40)

state_turnout %>% 
  filter(turnout_pct > 5) %>% 
  filter(year == 2016)

state_turnout %>% 
  mutate(turnout_pct = 5*floor(turnout_pct/5)) %>% 
  group_by(turnout_pct) %>% 
  summarize(dem_win_rate = sum(dem_win)/n(), count = n(), wins = sum(dem_win)) %>% 
  # mutate(turnout_window = toString(turnout_pct)+ "% to " + toString(turnout_pct +5) + "%")
  ggplot(aes(x = turnout_pct, y = dem_win_rate))+
  geom_col()
  
  
  
  