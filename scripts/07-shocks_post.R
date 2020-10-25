library(tidyverse)
library(usmap)

setwd("~/gov1347/election_analytics_blog/scripts")

state_cases <- read_csv("../data/United_States_COVID-19_Cases_and_Deaths_by_State_over_Time.csv")
pop_density <- read_csv("../data/pop_density.csv")
battleground <- read_csv("../data/battleground.csv")

`%notin%` <- Negate(`%in%`)

# From lab we know we we can find the total number of cases and deaths to date in each state
# with the following code.
totals <- state_cases %>% 
  group_by(state) %>% 
  summarize(total_cases = max(tot_cases), total_deaths = max(tot_death)) %>% 
  ungroup() %>% 
  filter(state %notin% c('AS', 'FSM', 'NYC', 'GU', 'MP', 'RMI', 'PW', 'PR', 'VI')) %>% 
  mutate(death_rate = total_deaths/total_cases)

deaths_pop<- battleground %>% 
  left_join(pop_density, by = c('state')) %>% 
  mutate(state = ifelse(state == 'D.C.', 'DC', setNames(state.abb, state.name)[state])) %>% 
  left_join(totals, by = c('state'))

death_frac <- deaths_pop %>% 
  #filter(lean == 's') %>% 
  mutate(death_frac = total_deaths/population) %>% 
  arrange(desc(death_frac))

# This does flat change through governor
death_frac_clean <- tibble::rowid_to_column(death_frac, "rank") %>% 
  mutate(success = (rank>ceiling(n()/2))) %>% 
  mutate(favors_trump = (str_detect(governor, 'r')+success != 1)) %>% 
  select(-lean, -electors)

# scaled change through governor INCOMPLETE
death_frac_clean <- tibble::rowid_to_column(death_frac, "rank") %>% 
  mutate(success = (rank>ceiling(n()/2))) %>% 
  mutate(favors_trump = (str_detect(governor, 'r')+success != 1)) %>% 
  select(-lean, -electors)

# flat change direct
fd_death_frac_clean <- tibble::rowid_to_column(death_frac, "rank") %>% 
  mutate(favors_trump = (rank>ceiling(n()/2))) %>% 
  select(-lean, -electors)

# scaled change direct
sd_death_frac_clean <- tibble::rowid_to_column(death_frac, "rank") %>% 
  mutate(favors_trump = 8*(rank-1)/50 - 4) %>% 
  select(-lean, -electors)

# ==========
# For code below this point it is necessary to run my script from the air game which 
# is called 05-air_game_blog.R.
# This will allow me to use covid to tune a former prediction, rather than attempt
# to make a prediction from scratch, which would likely be unreasonable.
# ==========

# Using an object from that other script, we can compare the 

#flat governor
new_prediction <- death_frac_clean %>% 
  left_join(prediction, by = 'state') %>%
  mutate(pressure_toward_trump = str_detect(lean, 's')*(2*favors_trump-1)) %>% 
  mutate(new_prediction = trump_predicted_winner + pressure_toward_trump) %>% 
  mutate(trump_wins_state = (new_prediction > 0))

# scaled governor

#flat direct
fd_new_prediction <- fd_death_frac_clean %>% 
  left_join(prediction, by = 'state') %>%
  mutate(pressure_toward_trump = str_detect(lean, 's')*(2*favors_trump-1)) %>% 
  mutate(new_prediction = trump_predicted_winner + pressure_toward_trump) %>% 
  mutate(trump_wins_state = (new_prediction > 0))

# scaled direct
sd_new_prediction <- fd_death_frac_clean %>% 
  left_join(prediction, by = 'state') %>%
  mutate(new_prediction = prediction + favors_trump) %>% 
  mutate(trump_wins_state = (new_prediction > 50))


fd_new_prediction %>% 
  filter(trump_predicted_winner != trump_wins_state) %>% 
  select(state, trump_predicted_winner, trump_wins_state)

sd_new_prediction %>% 
  filter(trump_predicted_winner != trump_wins_state) %>% 
  select(state, trump_predicted_winner, trump_wins_state)

new_prediction %>% 
  filter(lean == 's') %>% 
  select(state, trump_predicted_winner, trump_wins_state, prediction)

# flat governor
plot_usmap(data = new_prediction, regions = "states", values = "trump_wins_state") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  labs(title = 'flat governor')

# scaled governor
# INCOMPLETE

# flat direct
plot_usmap(data = fd_new_prediction, regions = "states", values = "trump_wins_state") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  labs(title = 'flat direct')

# scaled direct
plot_usmap(data = sd_new_prediction, regions = "states", values = "trump_wins_state") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  labs(title = 'scaled direct')

sd_new_prediction %>% 
  filter(trump_wins_state) %>% 
  summarize(sum(electors))

sd_new_prediction %>% 
  select(state, prediction, new_prediction, trump_predicted_winner, trump_wins_state)
  
