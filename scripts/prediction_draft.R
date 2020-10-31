library(tidyverse)
library(lubridate)
library(usmap)
library(ggthemes)

# In this script I will write code in an effort to sort out the content of my final
# predictions. This script tends to be disorganized and unclear in its scheme. To see the
# code that generates everything for the final prediction blog post, please see 
# final_prediction.R (which is also in the scripts folder).

setwd("~/gov1347/election_analytics_blog/scripts")

vep_2020 <- read_csv("../data/vep_2020.csv")
vep <- read_csv("../data/vep_1980-2016.csv")
national_results <- read_csv("../data/popvote_1948-2016.csv")
state_results <- read_csv("../data/popvote_bystate_1948-2016.csv")
battleground <- read_csv("../data/battleground.csv")
national_polls <- read_csv("../data/pollavg_1968-2016.csv")
state_polls <- read_csv("../data/pollavg_bystate_1968-2016.csv")
current_polls <- read_csv("../data/polling_data_10-30.csv")

`%notin%` <- Negate(`%in%`)

vep_total <- rbind(vep, vep_2020) %>% 
  filter(year%%4==0)

full_results <- national_results %>% 
  filter(party == 'democrat') %>% 
  left_join(state_results, by = c("year")) %>% 
  select(year, state, D_pv2p, R_pv2p, pv2p) %>% 
# We exclude 1976 because we don't have vep
  filter(year > 1976) %>%
  mutate(nat_pop_dem = pv2p) %>% 
  select(-pv2p)

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

predicted_vote_shares %>% 
  ggplot(aes(x = predicted_nat_pop_dem, y = nat_pop_dem))+
  geom_point()

# We see that the aggregated effects of different turnouts in different states
# is very small, so we can reasonably make a national popular vote prediction based
# the popular votes in the different states scaled by the sizes of their voting
# eligible populations. This means we can predict national two party vote share 
# simply starting from our predicted state specific two party vote shares.


# Now to find the state level predictions:

# october_polls <- state_polls %>%
#   mutate(month = month(poll_date)) %>%
#   filter(year(poll_date)%%4 == 0) %>% 
#   filter(month >= 10) %>% 
#   group_by(year, state, party) %>% 
#   summarize(polling_avg = mean(avg_poll)) %>% 
#   ungroup() %>% 
#   pivot_wider(names_from = party, values_from = polling_avg) %>% 
#   mutate(normalize_dem = 100*democrat/(democrat + republican)) %>% 
#   mutate(normalize_rep = 100*republican/(democrat + republican)) %>% 
#   select(-democrat, -republican)

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
  
october_polls <- avg_state_polls %>% 
  group_by(state, year) %>%
  summarize(max_month = max(month)) %>% 
  left_join(avg_state_polls, by = c('state', 'year')) %>% 
  filter(month == max_month) %>% 
  select(-month, -max_month) %>% 
  filter(state %notin% c('NE-1', 'NE-2', 'NE-3', 'ME-1', 'ME-2'))

polls_vs_vote <- state_results %>%
  mutate(previous_dem = D_pv2p, previous_rep = R_pv2p) %>% 
  mutate(year = year + 4) %>% 
  select(state, year, previous_dem, previous_rep) %>% 
  left_join(state_results, by = c('state', 'year')) %>% 
  left_join(october_polls, by = c('state', 'year')) %>% 
  filter(year >= 1976) %>% 
  mutate(normalize_dem = ifelse(is.na(normalize_dem), previous_dem, normalize_dem)) %>% 
  mutate(normalize_rep = ifelse(is.na(normalize_rep), previous_rep, normalize_rep)) %>% 
  select(state, year, R_pv2p, D_pv2p, normalize_rep, normalize_dem) %>% 
  filter(year != 2020)

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

polls_vs_vote_V2 %>% 
  # =========== The following line may not be necessary
  # filter(normalize_rep > 20) %>% 
  # ===========
  ggplot(aes(x = normalize_rep, y = R_pv2p))+
  geom_point()+
  geom_smooth(method = "glm")+
  geom_abline(intercept = 0, slope = 1, color = 'Red')

lm_polling <- lm(R_pv2p ~ normalize_rep, data = polls_vs_vote_V2)
summary(lm_polling)  

# lm_polling <- lm(R_pv2p ~ normalize_rep, data = polls_vs_vote_V2%>% 
#                    filter(normalize_rep > 20) )
# summary(lm_polling)

# Now we can make a prediction on each of the states using the regression from the polling data:
final_prediction <- current_polls %>% 
  # normalizing to two-party
  mutate(trump_2p = 100*trump/(trump + biden), biden_2p = 100*biden/(trump + biden)) %>% 
  mutate(prediction = 1.03279*trump -1.13674) %>% 
  mutate(trump_predicted_winner = (prediction > 50)) %>% 
  mutate(trump = trump_2p, biden = biden_2p) %>% 
  select(-trump_2p, -biden_2p)

plot_usmap(data = final_prediction, regions = "states", values = "trump_predicted_winner") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "Prediction 2020 Electoral Map",
       subtitle = "Based on Updated Polls as of 10/30/2020")

polls_vs_vote_V2 %>% 
  mutate(prediction = 1.03279*normalize_rep -1.13674) %>% 
  mutate(error = prediction - normalize_rep) %>% 
  mutate(stratification = ifelse(normalize_rep < 40, "<40", 
                                 ifelse(40<=normalize_rep & normalize_rep<50, "40-50",
                                        ifelse(50<=normalize_rep & normalize_rep < 60, "50-60", ">60")))) %>% 
  group_by(stratification) %>% 
  summarize(stdev = (sum(error^2)/(n()-1))**(.5), count = n()) %>% 
  mutate(standard_error = stdev/(count)**(.5))

polls_vs_vote_V2 %>% 
  mutate(prediction = 1.03279*normalize_rep -1.13674) %>% 
  mutate(error = prediction - normalize_rep) %>% 
  mutate(stdev = (sum(error^2)/(n()-1))**(.5), count = n()) %>% 
  mutate(standard_error = stdev/(count)**(.5))


win_probabilities <- polls_vs_vote_V2 %>% 
  filter(40 <= normalize_rep & normalize_rep < 60) %>% 
  mutate(binned_rep = 2*floor((normalize_rep + .5)/2)) %>%
  mutate(rep_win = (R_pv2p > 50)) %>% 
  group_by(binned_rep) %>% 
  summarize(win_rate = sum(rep_win)/n())

win_probabilities %>% 
  ggplot(aes(x = binned_rep, y = win_rate))+
  geom_col()

win_rate_2020 <- final_prediction %>% 
  mutate(binned_rep = 2*floor((trump + .5)/2)) %>% 
  left_join(win_probabilities, by = 'binned_rep') %>% 
  mutate(win_rate = ifelse(!is.na(win_rate), win_rate, 
                           ifelse(binned_rep < 50, 0, 1))) %>% 
  select(state, win_rate, electors)

win_rate_2020 %>% 
  # filter(win_rate == 0) %>% 
  filter(win_rate != 0 & win_rate != 1) %>%
  mutate(votes = sum(electors)) %>% 
  View()

## ===========
## DO NOT RERUN ACCIDENTALLY
election_simulation <- win_rate_2020 %>% 
  mutate(randon_num = runif(51), trump_win = (win_rate > randon_num)) %>% 
  filter(trump_win) %>% 
  group_by(trump_win) %>% 
  summarize(electoral_votes = sum(electors)) %>% 
  ungroup() %>% 
  mutate(trump_win = (electoral_votes >= 269))

for (val in 1:9999)
{
  simulation <- win_rate_2020 %>% 
    mutate(randon_num = runif(51), trump_win = (win_rate > randon_num)) %>% 
    filter(trump_win) %>% 
    group_by(trump_win) %>% 
    summarize(electoral_votes = sum(electors)) %>% 
    ungroup() %>% 
    mutate(trump_win = (electoral_votes >= 269))
  election_simulation <- rbind(election_simulation, simulation)
}
## DO NOT RERUN ACCIDENTALLY
## ===========

election_simulation %>% 
  group_by(trump_win) %>% 
  summarize(wins = n())

election_simulation %>% 
  ggplot(aes(x = electoral_votes))+
  geom_histogram()+
  geom_vline(xintercept = 269,col="red")
