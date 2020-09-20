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
  #filter(year != 2020) %>% 
  filter(year%%4 == 0) %>% 
  filter(quarter == 3) %>% 
  mutate(stock_growth =stock_close-stock_open) %>% 
  select(year, RDI_growth, GDP_growth_qt, stock_growth, unemployment) %>% 
  right_join(popvote_df, by = 'year') %>% 
  filter(incumbent_party)

model_inc <- model %>% 
  filter(incumbent == TRUE)

model_non_inc <- model %>% 
  filter(incumbent == FALSE)
  
model %>% 
  ggplot(aes(x = RDI_growth, y = pv2p, color = incumbent))+
  geom_point()

model %>% 
  ggplot(aes(x = GDP_growth_qt, y = pv2p, color = incumbent))+
  geom_point()

model %>% 
  ggplot(aes(x = stock_growth, y = pv2p, color = incumbent))+
  geom_point()

model %>% 
  ggplot(aes(x = unemployment, y = pv2p, color = incumbent))+
  geom_point()

lm_inc_econ <- lm(RDI_growth ~ pv2p, data = model_inc)
summary(lm_inc_econ)

lm_non_inc_econ <- lm(RDI_growth ~ pv2p, data = model_non_inc)
summary(lm_non_inc_econ)

lm_econ <- lm(RDI_growth ~ pv2p, data = model)
summary(lm_econ)

lm_gdp <- lm(GDP_growth_qt ~ pv2p, data = model)
summary(lm_gdp)
  
  
  
  