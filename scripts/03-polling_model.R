library(tidyverse)
library(ggplot2)
library(lubridate)
library(zoo)
library(ggthemes)

setwd("~/gov1347/election_analytics_blog/scripts")

national_polls <- read_csv("../data/pollavg_1968-2016.csv")
state_polls <- read_csv("../data/pollavg_bystate_1968-2016.csv")
electoral_college <- read_csv("../data/ec_1952-2020.csv") 
pop_vote <- read_csv("../data/popvote_1948-2016.csv") 
pop_vote_state <- read_csv("../data/popvote_bystate_1948-2016.csv") 

# First we will take the data from national polls and map it onto two party vote 
# share as a function month in the election year
cleaned_nat <- national_polls %>% 
  mutate(month = month(poll_date)) %>% 
  select(year, party, avg_support, month) %>% 
  group_by(year, party, month) %>% 
  summarize(avg_support = mean(avg_support)) %>% 
  ungroup() %>% 
  mutate(dem_support = avg_support*str_detect(party, 'democrat')) %>% 
  mutate(rep_support = avg_support*str_detect(party, 'republican')) %>% 
  group_by(year, month) %>% 
  summarize(dem_support = sum(dem_support), rep_support = sum(rep_support)) %>% 
  ungroup() %>% 
# Now we normalize to two-party vote share
  mutate(dem2p = 100*dem_support/(dem_support + rep_support)) %>% 
  mutate(rep2p = 100*rep_support/(dem_support + rep_support)) %>% 
  select(-dem_support, -rep_support)

#Since we are concerned with the accuracy of the polls, we can compare the predicted
# republican vote share versus the ultimate republican vote share for that year
nat_accuracy <- pop_vote %>% 
  filter(winner) %>% 
  select(year, party, pv2p) %>% 
  mutate(rep_pv2p = abs(pv2p-100*str_detect(party, 'democrat'))) %>% 
  mutate(dem_pv2p = 100-rep_pv2p) %>% 
  select(-party, -pv2p) %>% 
  right_join(cleaned_nat, by = 'year') %>% 
  mutate(rep_diff = rep2p - rep_pv2p)

#Here we plot the difference in the prediction and the final republican vote share
nat_accuracy %>% 
  ggplot(aes(x = month, y = rep_diff))+
  geom_point()

# Now lets look at the accuracy of state polling

# Now we will use state-level data and map it onto electoral votes. First we look at polled
# support rates
cleaned_state <- state_polls %>% 
  mutate(month = month(poll_date)) %>% 
  select(year, state, party, avg_poll, month) %>% 
  group_by(year, state, party, month) %>% 
  summarize(avg_poll = mean(avg_poll)) %>% 
  ungroup() %>% 
  mutate(dem_support = avg_poll*str_detect(party, 'democrat')) %>% 
  mutate(rep_support = avg_poll*str_detect(party, 'republican')) %>% 
  group_by(year, state, month) %>% 
  summarize(dem_support = sum(dem_support), rep_support = sum(rep_support)) %>% 
  ungroup()

# Now we can map the candidate with greater support onto the state's electoral vote count.
electoral_college_mod <- electoral_college %>% 
  mutate(month1 = 1) %>% 
  mutate(month2 = 2) %>% 
  mutate(month3 = 3) %>% 
  mutate(month4 = 4) %>% 
  mutate(month5 = 5) %>% 
  mutate(month6 = 6) %>% 
  mutate(month7 = 7) %>% 
  mutate(month8 = 8) %>% 
  mutate(month9 = 9) %>% 
  mutate(month10 = 10) %>% 
  mutate(month11 = 11) %>% 
  mutate(month0 = 0) %>% 
  pivot_longer(cols = c('month0', 'month1', 'month2', 'month3', 'month4', 
                        'month5', 'month6', 'month7', 'month8', 'month9', 
                        'month10', 'month11'),
               values_to = "month") %>% 
  select(-name)

previous_winner <- pop_vote_state %>% 
  mutate(winner = (D > R)) %>% 
  select(year, state, winner) %>% 
  mutate(winner = str_replace(winner, "TRUE", "democrat")) %>% 
  mutate(winner = str_replace(winner, "FALSE", "republican")) %>% 
  mutate(year = year + 4)
  

electors <- cleaned_state %>% 
  right_join(electoral_college_mod, by = c('year', 'state', 'month')) %>% 
  arrange(year, state, month) %>% 
  left_join(previous_winner, by = c('year', 'state')) %>% 
  mutate(rep_elector = electors*(rep_support > dem_support)) %>% 
  group_by(year, state) %>%
  filter(!is.na(winner)) %>%
  mutate(rep_elector = ifelse(month==0, electors*str_detect(winner, "republican"), rep_elector)) %>% 
  fill(rep_elector, .direction = 'down') %>% 
  ungroup() %>% 
  filter(year >= 1972) %>% 
  group_by(year, month) %>% 
  summarize(republican_electoral_votes = sum(rep_elector))

# here we find the number of electoral votes earned by republicans in each election
state_accuracy <- electoral_college %>% 
  left_join(pop_vote_state, by = c('state', 'year')) %>% 
  mutate(rep_win = (R>D)) %>% 
  filter(rep_win) %>% 
  group_by(year) %>% 
  summarize(actual_republican_votes = sum(electors))
  
# Now we can plot the difference between the predicted and 
state_accuracy %>% 
  left_join(electors, by = c('year')) %>% 
  filter(month >=2) %>% 
  mutate(electoral_diff = 100*(republican_electoral_votes/538 - actual_republican_votes/538)) %>% 
  ggplot(aes(x = month(month, label= TRUE), y = electoral_diff))+
  geom_point()+
  labs(title = "Error in Electoral Vote Prediction Based on State Polls by Month",
       subtitle = "Normalized to 100 Total Electoral Votes",
       x = "Month",
       y = "Error in Electoral Vote prediction")+
  theme_solarized_2()


cleaned_nat %>% 
 # filter(year == 2012) %>% 
  group_by(year) %>% 
  ggplot(aes(x = month, y = 538*rep2p))+
  geom_point()
  
