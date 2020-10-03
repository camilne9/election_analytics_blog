library(tidyverse)

setwd("~/gov1347/election_analytics_blog/scripts")

pop_vote <- read_csv("../data/popvote_1948-2016.csv") 

pop_vote %>% 
  filter(incumbent == TRUE) %>% 
  summarize(avg_pv = mean(pv2p))
