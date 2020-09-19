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

model <- economy_df %>% 
  filter(year != 2020) %>% 
  filter(year%%4 == 0) %>% 
  filter(quarter == 3) %>% 
  select(year, RDI_growth, GDP_growth_qt) %>% 
  right_join(popvote_df, by = 'year') %>% 
  filter(incumbent_party) %>% 
  filter(year >= 1960)

model_inc <- model %>% 
  filter(incumbent == TRUE)

model_non_inc <- model %>% 
  filter(incumbent == FALSE)
  
model %>% 
  ggplot(aes(x = RDI_growth, y = pv2p, color = incumbent))+
  geom_point()

lm_inc_econ <- lm(RDI_growth ~ pv2p, data = model_inc)
summary(lm_inc_econ)

lm_non_inc_econ <- lm(RDI_growth ~ pv2p, data = model_non_inc)
summary(lm_non_inc_econ)

lm_econ <- lm(RDI_growth ~ pv2p, data = model)
summary(lm_econ)
  
  
  
  