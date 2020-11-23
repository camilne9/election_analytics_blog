# This is the script with the code relevant for my reflection 
# blog post. It is also worth viewing final_prediction.R to
# see the code for my model and generating the graphics summarizing
# my predictions.

library(tidyverse)
library(lubridate)
library(usmap)
library(ggthemes)
library(gt)
library(caret)
library(webshot)
library(janitor)

setwd("~/gov1347/election_analytics_blog/scripts")

# I read in the data
results <- read_csv("../data/results2020_11-11.csv")
final_prediction <- read_csv("../data/final_prediction.csv")
all_results <- read_csv("../data/popvote_bystate_1948-2020.csv")
electors <- read_csv("../data/battleground.csv")
enos_results <- read_csv("../data/StateResults2020.csv") %>% 
  clean_names()

# I create a cleaner version of the results that Professor Enos provided
# including two party vote share
clean_results <- enos_results %>% 
  mutate(state = geographic_name) %>% 
  filter(state != "name") %>% 
  mutate(trump_2p = 100*as.integer(donald_j_trump)/(as.integer(donald_j_trump)+as.integer(joseph_r_biden_jr))) %>% 
  mutate(biden_2p = 100*as.integer(joseph_r_biden_jr)/(as.integer(donald_j_trump)+as.integer(joseph_r_biden_jr))) %>%
  mutate(trump_winner = (trump_2p > biden_2p)) %>% 
  select(state, trump_2p, biden_2p, trump_winner)

# I find the national two party vote share.
enos_results %>% 
  filter(geographic_name != 'name') %>% 
  group_by() %>% 
  summarize(biden = sum(as.integer(joseph_r_biden_jr)), trump = sum(as.integer(donald_j_trump))) %>% 
  mutate(total = biden + trump) %>%
  mutate(biden_share = biden/total, trump_share = trump/total)

# I join the results with the electoral vote counts for each state
elector_results <- clean_results %>% 
  left_join(electors, by = 'state') %>% 
  mutate(electors = ifelse(state == "District of Columbia", 3, electors)) %>% 
  select(-lean)

# Check Biden electoral Vote count
elector_results %>% 
  filter(trump_winner == FALSE) %>% 
  group_by(trump_winner) %>% 
  summarize(sum(electors))

# Check Trump electoral Vote count
elector_results %>% 
  filter(trump_winner == TRUE) %>% 
  group_by(trump_winner) %>% 
  summarize(sum(electors))

# Generate plot of the actual results of the election
plot_usmap(data = elector_results, regions = "states", values = "trump_winner") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "Actual 2020 Presidential Electoral Map",
       subtitle = "Biden Defeated Trump 306-232",
       caption = "NE and ME districts not shown")  

ggsave("../figures/actual_election_results.png", height = 6, width = 8)

# I join the actual results with the data frame of my predictions 
comparison <- elector_results %>% 
  left_join(final_prediction, by = c("state", "electors"))

# I find the differences between my predictions and the results
analysis <- comparison %>% 
  mutate(error = prediction - trump_2p) %>% 
  mutate(within_rmse = abs(error) < 2.734152) %>% 
  mutate(within_2rmse = abs(error) < 2*2.734152) %>% 
  mutate(underestimated_trump = (error < 0))

# I visualize the error by mapping the difference between predicted and actual vote share.
plot_usmap(data = analysis, regions = "states", values = "error") + 
  scale_fill_gradient2(
    high = "blue", 
    mid = "white",
    low = "red", 
    breaks = c(-10,-5,0,5,10), 
    limits = c(-10,10),
    name = "Error"
  ) +
  theme_void()+
  labs(title = "Difference Between Predict and Actual Vote Share for Trump",
       subtitle = "(Red Indicates Trump Outperfroming Prediction)") 

ggsave("../figures/error_by_state_map.png", height = 6, width = 8)

# Showing states that were predicted within one rmse of the actual result
plot_usmap(data = analysis, regions = "states", values = "within_rmse") + 
  scale_fill_manual(values = c("black", "green"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "States Predicted within One RMSE of the Result",
       subtitle = "Successful Cases Shown in Green")

ggsave("../figures/within_1rmse_map.png", height = 6, width = 8)

# Showing states that were predicted within two rmse of the actual result
plot_usmap(data = analysis, regions = "states", values = "within_2rmse") + 
  scale_fill_manual(values = c("black", "green"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "States Predicted within Two RMSE of the Result",
       subtitle = "Successful Cases Shown in Green")

ggsave("../figures/within_2rmse_map.png", height = 6, width = 8)

# Showing states where I overestimated Trump
plot_usmap(data = analysis, regions = "states", values = "underestimated_trump") + 
  scale_fill_manual(values = c("yellow", "black"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "States where Trump Exceeded my Prediction",
       subtitle = "Successful Cases Shown in Yellow") 

ggsave("../figures/overestimated_trump_map.png", height = 6, width = 8)

# I calculate the RMSE of my prediction
analysis %>% 
  group_by() %>% 
  summarize(sqrt(sum(error^2)))

# I calculate the brier score of my prediction
analysis %>% 
  mutate(incorrect_prediction = (trump_winner != trump_predicted_winner)) %>% 
  select(state, incorrect_prediction) %>%
  group_by() %>% 
  summarize(brier_score = sum(incorrect_prediction)/n())

# I create a map showing whether I correctly or incorrectly predicted each state
plot_usmap(data = analysis %>% mutate(incorrect_prediction = (trump_winner != trump_predicted_winner)), 
           regions = "states", values = "incorrect_prediction") + 
  scale_fill_manual(values = c("turquoise2", "black"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "States where I Correctly Predicted the Winner",
       subtitle = "Successful Cases Shown in Turquoise") 

ggsave("../figures/accuracy_of_prediction.png", height = 6, width = 8)  