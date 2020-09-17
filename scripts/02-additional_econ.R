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


