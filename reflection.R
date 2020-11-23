library(tidyverse)
library(lubridate)
library(usmap)
library(ggthemes)
library(gt)
library(caret)
library(webshot)

setwd("~/gov1347/election_analytics_blog/scripts")

results <- read_csv("../data/results2020_11-11.csv")
final_prediction <- read_csv("../data/final_prediction.csv")
all_results <- read_csv("../data/popvote_bystate_1948-2020.csv")
electors <- read_csv("../data/battleground.csv")

results_2p <- results %>% 
  mutate(trump_2p = 100*trump/(trump+biden)) %>% 
  mutate(biden_2p = 100*biden/(trump+biden)) %>%
  mutate(trump_winner = (trump_2p > biden_2p)) %>% 
  select(-trump, -biden)

official_results <- all_results %>% 
  filter(year == 2020) %>% 
  mutate(trump_winner = (R_pv2p > D_pv2p)) %>% 
  select(state, trump_winner, R_pv2p, D_pv2p) %>% 
  left_join(electors, by = 'state') %>% 
  mutate(electors = ifelse(state == "District of Columbia", 3, electors)) %>% 
  select(-lean)
  

# Check Biden electoral Vote count
results_2p %>% 
  filter(trump_winner == FALSE) %>% 
  group_by(trump_winner) %>% 
  summarize(sum(electors))

# Check Trump electoral Vote count
results_2p %>% 
  filter(trump_winner == FALSE) %>% 
  group_by(trump_winner) %>% 
  summarize(sum(electors))

# Dummy check to make sure I entered the data correctly
plot_usmap(data = official_results, regions = "states", values = "trump_winner") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "Actual 2020 Electoral Map")  

comparison <- official_results %>% 
  left_join(final_prediction, by = c("state", "electors"))

analysis <- comparison %>% 
  mutate(error = prediction - 100*R_pv2p) %>% 
  mutate(rmse = abs(error) < 2.734152) %>% 
  mutate(underestimated_trump = (error < 0))

plot_usmap(data = analysis, regions = "states", values = "error") + 
 # scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "Error in Prediction") 

plot_usmap(data = analysis, regions = "states", values = "rmse") + 
  scale_fill_manual(values = c("pink", "green"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "Within 1 rmse")

plot_usmap(data = analysis, regions = "states", values = "underestimated_trump") + 
  scale_fill_manual(values = c("black", "yellow"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "underestimated trump in yellow") 

analysis %>% 
  group_by() %>% 
  summarize(sqrt(sum(error^2)))
  