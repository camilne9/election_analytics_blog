library(tidyverse)
library(janitor)

setwd("~/gov1347/election_analytics_blog/scripts")

polling_averages <- read_csv("../data/StatePollAverages.csv") %>% 
  clean_names()

polling_averages %>% 
  # filter(!is.na(trump_percent_actual))
  mutate(recent_diff = trump_percent_actual - trump_weighted_average_recent) %>% 
  select(state_abb, trump_percent_actual, trump_weighted_average_recent, recent_diff) %>% 
  filter(!is.na(recent_diff)) %>% 
  arrange(recent_diff)
