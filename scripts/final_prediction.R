library(tidyverse)
library(lubridate)
library(usmap)
library(ggthemes)
library(gt)

# In this script I generate all of the relevant content for my final prediction blog post.

setwd("~/gov1347/election_analytics_blog/scripts")

# First I load in the relevant data sets
vep_2020 <- read_csv("../data/vep_2020.csv")
vep <- read_csv("../data/vep_1980-2016.csv")
national_results <- read_csv("../data/popvote_1948-2016.csv")
state_results <- read_csv("../data/popvote_bystate_1948-2016.csv")
battleground <- read_csv("../data/battleground.csv")
national_polls <- read_csv("../data/pollavg_1968-2016.csv")
state_polls <- read_csv("../data/pollavg_bystate_1968-2016.csv")
current_polls <- read_csv("../data/polling_data_10-30.csv")

`%notin%` <- Negate(`%in%`)

# I add 2020 VEP data to the data set of past VEP data.
vep_total <- rbind(vep, vep_2020) %>% 
  filter(year%%4==0)

# First I consider whether weighting state level 2-party vote share gives
# a good estimate of the national 2-party vote share.

# I merge data of state and national results of vote share
full_results <- national_results %>% 
  filter(party == 'democrat') %>% 
  left_join(state_results, by = c("year")) %>% 
  select(year, state, D_pv2p, R_pv2p, pv2p) %>% 
  # We exclude 1976 because we don't have vep
  filter(year > 1976) %>%
  mutate(nat_pop_dem = pv2p) %>% 
  select(-pv2p)

# I merge the results data frame with the VEP data
predicted_vote_shares <- full_results %>% 
  left_join(vep_total, by = c('state', 'year')) %>% 
  mutate(dem_votes = D_pv2p*VEP) %>% 
  mutate(rep_votes = R_pv2p*VEP) %>% 
  group_by(year) %>% 
  summarize(nat_pop_dem = mean(nat_pop_dem),
            dem_votes = sum(dem_votes), 
            rep_votes = sum(rep_votes)) %>% 
  ungroup() %>% 
  mutate(predicted_nat_pop_dem = 100*dem_votes/(dem_votes+rep_votes))

# I plot the results
predicted_vote_shares %>% 
  ggplot(aes(x = predicted_nat_pop_dem, y = nat_pop_dem))+
  geom_smooth(method = "glm")+
  geom_abline(intercept = 0, slope = 1, color = 'Red')+
  geom_point()+
  labs(title = "Predicted vs Actual National Two-Party Vote Share \n Based on Weighted State-Level Vote Share",
       subtitle = "From 1980 to 2016",
       x = " Predicted National Two-Party Vote Share",
       y = " Actual National Two-Party Vote Share")+
  theme_minimal()

ggsave("../figures/national_votes_from_states.png", height = 6, width = 8)

# We see that the aggregated effects of different turnouts in different states
# is very small, so we can reasonably make a national popular vote prediction based
# the popular votes in the different states scaled by the sizes of their voting
# eligible populations. This means we can predict national two party vote share 
# simply starting from our predicted state specific two party vote shares.


# Now I will work on making state level predictions

# I average the polling data in each month (for each year, state, and party)
# and I count November and October together because there's limited November data.
# I normalize to two-party vote share.
avg_state_polls <- state_polls %>% 
  mutate(month = month(poll_date)) %>%
  filter(year(poll_date)%%4 == 0) %>% 
  mutate(month = ifelse(month==11, 10, month)) %>% 
  group_by(month, state, year, party) %>% 
  summarize(polling_avg = mean(avg_poll)) %>%
  ungroup() %>% 
  pivot_wider(names_from = party, values_from = polling_avg) %>% 
  mutate(normalize_dem = 100*democrat/(democrat + republican)) %>% 
  mutate(normalize_rep = 100*republican/(democrat + republican)) %>% 
  select(-democrat, -republican)

# I restrict myself only to the most recent month in which there was polling.
# I am not looking at the districts because I don;t have good historical
# district level polling data.
october_polls <- avg_state_polls %>% 
  group_by(state, year) %>%
  summarize(max_month = max(month)) %>% 
  left_join(avg_state_polls, by = c('state', 'year')) %>% 
  filter(month == max_month) %>% 
  select(-month, -max_month) %>% 
  filter(state %notin% c('NE-1', 'NE-2', 'NE-3', 'ME-1', 'ME-2'))

# I merge polling data with the actual results
polls_vs_vote_V2 <- state_results %>%
  mutate(previous_dem = D_pv2p, previous_rep = R_pv2p) %>% 
  mutate(year = year + 4) %>% 
  select(state, year, previous_dem, previous_rep) %>% 
  left_join(state_results, by = c('state', 'year')) %>% 
  left_join(october_polls, by = c('state', 'year')) %>% 
  filter(year >= 1976) %>% 
  filter(!is.na(normalize_dem)) %>% 
  select(state, year, R_pv2p, D_pv2p, normalize_rep, normalize_dem) %>% 
  filter(year != 2020)

# I plot polling data vs actual result for republicans. I show the regression
# line (and y = x for reference).
polls_vs_vote_V2 %>% 
  ggplot(aes(x = normalize_rep, y = R_pv2p))+
  geom_point()+
  geom_smooth(method = "glm")+
  geom_abline(intercept = 0, slope = 1, color = 'Red')+
  labs(title = "Republican Polling Average vs Actual Republican Vote Share",
       subtitle = "From 1976 to 2016",
       x = "Republcian Two-Party Polling Average",
       y = "Actual Republican Two-Party Vote Share")+
  theme_minimal()

ggsave("../figures/polling_vs_actual.png", height = 6, width = 8)

# I generate the Regression Line Object:
lm_polling <- lm(R_pv2p ~ normalize_rep, data = polls_vs_vote_V2)
summary(lm_polling)  

# I do leave-one-out validation

###### MUST DO THIS VALIDATION

# Now we can make a prediction on each of the states using the regression from the polling data:
final_prediction <- current_polls %>% 
  # normalizing to two-party
  mutate(trump_2p = 100*trump/(trump + biden), biden_2p = 100*biden/(trump + biden)) %>% 
  mutate(prediction = 1.03279*trump_2p -1.13674) %>% 
  mutate(trump_predicted_winner = (prediction > 50)) %>% 
  mutate(trump = trump_2p, biden = biden_2p) %>% 
  select(-trump_2p, -biden_2p)

# I plot what this result would look like.
plot_usmap(data = final_prediction, regions = "states", values = "trump_predicted_winner") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "Prediction 2020 Electoral Map",
       subtitle = "Based on Updated Polls as of 10/30/2020")

ggsave("../figures/polling_state_predictions.png", height = 6, width = 8)

# To consider the uncertainty, I generate the standard error in different clusters along the 
# regression line
standard_errors <- polls_vs_vote_V2 %>% 
  mutate(prediction = 1.03279*normalize_rep -1.13674) %>% 
  mutate(error = prediction - normalize_rep) %>%
  mutate(stratification = 5*floor((normalize_rep + 5/2)/5)) %>%
  group_by(stratification) %>% 
  summarize(stdev = (sum(error**2)/(n()-1))**(.5), count = n()) %>% 
  mutate(standard_error = stdev/(count)**(.5)) %>%
  mutate(standard_error = ifelse(stratification == 10, 0.95591132, standard_error)) %>% 
  filter(standard_error != Inf) %>% 
  select(stratification, standard_error)

# I merge the standard errors with the tibble with current polls and predictions:
final_prediction %>% 
  mutate(stratification = 5*floor((trump + 5/2)/5)) %>%
  left_join(standard_errors, by = 'stratification') %>% 
  mutate(State = state, 
         "Trump Vote Share" = prediction, 
         "Biden Vote Share" = 100 - prediction,
         Margin = round(2*standard_error, digits = 2)) %>%
  mutate(Margin = paste("±", Margin)) %>% 
  select(State, "Trump Vote Share", "Biden Vote Share", Margin) %>% 
  gt() %>% 
  tab_header("Predicted State-Level Two-Party Vote Shares")

# Now I can use the state vote predictions to make a national popular vote share prediction.
vep_total %>% 
  filter(year ==2020) %>% 
  filter(state != "United States") %>% 
  select(state, VEP) %>% 
  right_join(final_prediction, by = 'state') %>% 
  mutate(trump_votes = prediction*VEP/100, dummy_var = TRUE) %>%
  group_by(dummy_var) %>% 
  summarize(total_trump = sum(trump_votes), total_votes = sum(VEP)) %>% 
  ungroup() %>% 
  mutate(trump_percent = 100*total_trump/total_votes)

# Now I will simulate the election 10,000 times. I will generate win probabilities in
# each state based on the historical record of win odds for states in various regions 
# of polling.
win_probabilities <- polls_vs_vote_V2 %>% 
  filter(40 <= normalize_rep & normalize_rep < 60) %>% 
  mutate(binned_rep = 5*floor((normalize_rep + 5/2)/5)) %>%
  mutate(rep_win = (R_pv2p > 50)) %>% 
  group_by(binned_rep) %>% 
  summarize(win_rate = sum(rep_win)/n())

# I plot these win probabilities for clarity.
win_probabilities %>% 
  ggplot(aes(x = binned_rep, y = win_rate))+
  geom_col()+
  labs(title = "Republican Win Probabilities by Polling Average",
       x = "Republican Polling Average",
       y = "Win Probability")+
  theme_minimal()

ggsave("../figures/win_probabilities.png", height = 6, width = 8)

# Now I simulate the election 10,000 times with win odds for each state
# determined by the republican polling average in the state.

# First I apply the win probabilities to each state based on polling.
win_rate_2020 <- final_prediction %>% 
  mutate(binned_rep = 5*floor((trump + 5/2)/5)) %>% 
  left_join(win_probabilities, by = 'binned_rep') %>% 
  mutate(win_rate = ifelse(!is.na(win_rate), win_rate, 
                           ifelse(binned_rep < 50, 0, 1))) %>% 
  select(state, win_rate, electors)

# ================
# Now I run the actual simulation.
election_simulation <- win_rate_2020 %>% 
  mutate(randon_num = runif(51), trump_win = (win_rate > randon_num)) %>% 
  filter(trump_win) %>% 
  group_by(trump_win) %>% 
  summarize(electoral_votes = sum(electors)) %>% 
  ungroup() %>% 
  mutate(trump_win = (electoral_votes >= 269))

for (val in 1:9999){
  simulation <- win_rate_2020 %>% 
    mutate(randon_num = runif(51), trump_win = (win_rate > randon_num)) %>% 
    filter(trump_win) %>% 
    group_by(trump_win) %>% 
    summarize(electoral_votes = sum(electors)) %>% 
    ungroup() %>% 
    mutate(trump_win = (electoral_votes >= 269))
  election_simulation <- rbind(election_simulation, simulation)
}
# ================

# Now we can plot the results of the simulations
election_simulation %>% 
  ggplot(aes(x = electoral_votes))+
  geom_histogram(bins = 40)+
  geom_vline(xintercept = 269,col="blue")+
  geom_vline(xintercept = mean(election_simulation$electoral_votes),col="Red")+
  labs(title = "Simulated Electoral Results for Trump",
       subtitle = "Based on State Win Probabilities",
       x = "Electoral Votes",
       y = "Number of Simulations")+
  theme_minimal()

ggsave("../figures/simulated_electoral_vote.png", height = 6, width = 8)

