# In this script I create all of the dataframes/plots/regressions for 
# my model and post on predicting elections based on the economy.

library(tidyverse)
library(ggplot2)
library(usmap)
library(ggthemes)
library(janitor)

setwd("~/gov1347/election_analytics_blog/scripts")

# Here I load all the data given data about election results and 
# the US economy surrounding those results.

popvote_df <- read_csv("../data/popvote_1948-2016.csv")
pvstate_df <- read_csv("../data/popvote_bystate_1948-2016.csv")
economy_df <- read_csv("../data/econ.csv") 
popvote_df <- read_csv("../data/popvote_1948-2016.csv") 
local_econ_df <- read_csv("../data/local.csv")
electoral_college_df <- read_csv("../data/ec_1952-2020.csv")

# I am going to consider a models based on growth in GDP, stock growth, and RDI in the 
# third quarter of election year. The restriction to 3rd quarter is motivated by the fact
# voters tend to overweight the most recent data. I will ulitamtely chose which of these
# variables will be used in my model based on the linear regression's r^2 value.

model <- economy_df %>% 
  filter(year%%4 == 0) %>% 
  filter(quarter == 3) %>% 
  mutate(stock_growth =stock_close-stock_open) %>% 
  select(year, RDI_growth, GDP_growth_qt, stock_growth, unemployment) %>% 
  right_join(popvote_df, by = 'year') %>% 
  filter(incumbent_party) %>% 
  select(-candidate, -pv, -prev_admin) %>% 
  mutate(older = (year < 1990))

# Below I isolate incumbent candidates from candidates of the incumbent party.

model_inc <- model %>% 
  filter(incumbent == TRUE)

model_non_inc <- model %>% 
  filter(incumbent == FALSE)

# Below I separate the "older" elections from the "newer" elections to see if the
# predictions/predictive power of the economy has changed over time.
model_older <- model %>% 
  filter(older == TRUE)

model_newer <- model %>% 
  filter(older == FALSE)


# Now I create simple plots of the relation between the relevant variables
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

# Now I check the predictive ability of models based on different variables
lm_econ <- lm(RDI_growth ~ pv2p, data = model)
summary(lm_econ)

lm_gdp <- lm(GDP_growth_qt ~ pv2p, data = model)
summary(lm_gdp)

lm_stock <- lm(stock_growth ~ pv2p, data = model)
summary(lm_gdp)

lm_unemp <- lm(unemployment ~ pv2p, data = model)
summary(lm_gdp)

# I observe that RDI growth shows the best predictive power, so I will
# chose my model based on 3rd quarter RDI growth

lm_inc_econ <- lm(RDI_growth ~ pv2p, data = model_inc)
summary(lm_inc_econ)

lm_non_inc_econ <- lm(RDI_growth ~ pv2p, data = model_non_inc)
summary(lm_non_inc_econ)

lm_older <- lm(RDI_growth ~ pv2p, data = model_older)
summary(lm_inc_econ)

lm_newer <- lm(RDI_growth ~ pv2p, data = model_newer)
summary(lm_non_inc_econ)

# Now I create a nicer plot showing the scatter plots with their regression lines
# for the RDI growth base case and the cases that consider the effect of 
# incumbency and the effect of time.

model %>% 
  ggplot(aes(x = RDI_growth, y = pv2p))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)+
  labs(title = "Two Party Vote Share of Incumbent Party by RDI Growth",
       subtitle = "",
       x = "RDI Growth in 3rd quarter of Election Year",
       y = "Two Party Vote Share of Incumbent Party")+
  theme_solarized_2()

ggsave("../figures/rdi_growth_basic.png", height = 4, width = 8)

model %>% 
  mutate(incumbent = str_replace(incumbent, "FALSE", "Non-Incumbent")) %>% 
  mutate(incumbent = str_replace(incumbent, "TRUE", "Incumbent")) %>% 
  ggplot(aes(x = RDI_growth, y = pv2p, color = incumbent))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)+
  labs(title = "Two Party Vote Share of Incumbent Party by RDI Growth",
       subtitle = "Incumbent Candidate vs Non-Incumbent Candidate",
       x = "RDI Growth in 3rd quarter of Election Year",
       y = "Two Party Vote Share of Incumbent Party")+
  theme_solarized_2()+
  theme(legend.title = element_blank())

ggsave("../figures/rdi_growth_incumbent.png", height = 4, width = 8)

model %>% 
  mutate(older = str_replace(older, "TRUE", "1960-1988")) %>% 
  mutate(older = str_replace(older, "FALSE", "1992-2016")) %>% 
  ggplot(aes(x = RDI_growth, y = pv2p, color = older))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)+
  labs(title = "Two Party Vote Share of Incumbent Party by RDI Growth",
       subtitle = "Incumbent Candidate vs Non-Incumbent Candidate",
       x = "RDI Growth in 3rd quarter of Election Year",
       y = "Two Party Vote Share of Incumbent Party")+
  theme_solarized_2()+
  scale_fill_discrete(name = "Election Years")+
  theme(legend.title = element_blank())

ggsave("../figures/rdi_growth_age.png", height = 4, width = 8)
  
  
  
  