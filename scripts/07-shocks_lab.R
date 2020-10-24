library(tidyverse)
library(usmap)

setwd("~/gov1347/election_analytics_blog/scripts")

state_cases <- read_csv("../data/United_States_COVID-19_Cases_and_Deaths_by_State_over_Time.csv")

`%notin%` <- Negate(`%in%`)

totals <- state_cases %>% 
  group_by(state) %>% 
  summarize(total_cases = max(tot_cases), total_deaths = max(tot_death)) %>% 
  ungroup() %>% 
  filter(state %notin% c('AS', 'FSM', 'NYC', 'GU', 'MP', 'RMI', 'PW', 'PR', 'VI')) %>% 
  mutate(death_rate = total_deaths/total_cases)

totals %>% 
  mutate(death_rate = total_deaths/total_cases) %>% 
  arrange(desc(death_rate)) %>% 
  ggplot(aes(x = total_cases, y = death_rate))+
  geom_point()

totals %>% 
  mutate(death_rate = total_deaths/total_cases) %>% 
  arrange(desc(death_rate))

plot_usmap(data = totals, regions = "state", values = "death_rate") 
# + 
#   scale_fill_manual(values = c("blue", "red"), name = "state winner") +
#   theme_void()+
#   theme(legend.position = 'None')+
#   labs(title = "2020 Electoral Map Predicted by Polling",
#        subtitle = "Polling from 10/17")
