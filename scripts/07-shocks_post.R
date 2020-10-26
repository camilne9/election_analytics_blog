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

# We combine the relevant data sets to get population, death counts, electors, and
# state leans together.
deaths_pop<- battleground %>% 
  left_join(pop_density, by = c('state')) %>% 
  mutate(state = ifelse(state == 'D.C.', 'DC', setNames(state.abb, state.name)[state])) %>% 
  left_join(totals, by = c('state'))

# We get the death rate per capita and arrange the tibble in from worst job to best job.
death_frac <- deaths_pop %>% 
  mutate(death_frac = total_deaths/population) %>% 
  arrange(desc(death_frac))

# Below we perform similar manipulations for the four different cases I am considering.
# The results have a variable called "favors_trump" that will be used for the correction
# to my previous model.

# This assumes binary success/failure and attributes responsibility to the governor.
# I call this "binary governor" model
fg_death_frac_clean <- tibble::rowid_to_column(death_frac, "rank") %>% 
  mutate(success = (rank>ceiling(n()/2))) %>% 
  mutate(favors_trump = (str_detect(governor, 'r')+success != 1)) %>% 
  select(-lean, -electors)

# This assumes scaled success/failure and attributes responsibility to the governor
# I call this "scaled governor" model
sg_death_frac_clean <- tibble::rowid_to_column(death_frac, "rank") %>% 
  mutate(favors_governor = 10*(rank-1)/50 - 5) %>% 
  mutate(favors_trump = (2*str_detect(governor, 'r')-1)*favors_governor) %>% 
  select(-lean, -electors)

# This assumes binary success/failure and attributes responsibility to the president
# I call this "binary president" model
fp_death_frac_clean <- tibble::rowid_to_column(death_frac, "rank") %>% 
  mutate(favors_trump = (rank>ceiling(n()/2))) %>% 
  select(-lean, -electors)

# This assumes scaled success/failure and attributes responsibility to the president
# I call this "scaled president" model
sp_death_frac_clean <- tibble::rowid_to_column(death_frac, "rank") %>% 
  mutate(favors_trump = 10*(rank-1)/50 - 5) %>% 
  select(-lean, -electors)

# ==========
# For code below this point it is necessary to run my script from the air game which 
# is called 05-air_game_blog.R.
# This will allow me to use covid to tune a former prediction, rather than attempt
# to make a prediction from scratch, which would likely be unreasonable.
# ==========

# Using an object from that other script, we can update the prediction. For "flat" models,
# I simply reverse the result if there is discrepency between the old prediction and the
# effect of coronavirus. In "scaled" models, I shift the popular vote prediction by between
# + and - 5% depending on the rank.

# "flat governor" correction to the model based on rank
fg_new_prediction <- fg_death_frac_clean %>% 
  left_join(prediction, by = 'state') %>%
  mutate(pressure_toward_trump = str_detect(lean, 's')*(2*favors_trump-1)) %>% 
  mutate(new_prediction = trump_predicted_winner + pressure_toward_trump) %>% 
  mutate(trump_wins_state = (new_prediction > 0))

# "scaled governor" correction to the model based on rank
sg_new_prediction <- sg_death_frac_clean %>% 
  left_join(prediction, by = 'state') %>% 
  mutate(new_prediction = prediction + favors_trump) %>% 
  mutate(trump_wins_state = (new_prediction > 50))

# "flat president" correction to the model based on rank
fp_new_prediction <- fp_death_frac_clean %>% 
  left_join(prediction, by = 'state') %>%
  mutate(pressure_toward_trump = str_detect(lean, 's')*(2*favors_trump-1)) %>% 
  mutate(new_prediction = trump_predicted_winner + pressure_toward_trump) %>% 
  mutate(trump_wins_state = (new_prediction > 0))

# "scaled president" correction to the model based on rank
sp_new_prediction <- fp_death_frac_clean %>% 
  left_join(prediction, by = 'state') %>%
  mutate(new_prediction = prediction + favors_trump) %>% 
  mutate(trump_wins_state = (new_prediction > 50))

# Below I make the relevant maps.

# I make the map for the "flat governor" model
plot_usmap(data = fg_new_prediction, regions = "states", values = "trump_wins_state") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = '2020 Presidential Prediction by Ad Spending and Coronavirus Effects',
       subtitle = 'Effects Applied to the Governors on a Binary Basis')

ggsave("../figures/prediction_flat_governor.png", height = 6, width = 8)

# scaled governor
plot_usmap(data = sg_new_prediction, regions = "states", values = "trump_wins_state") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = '2020 Presidential Prediction by Ad Spending and Coronavirus Effects',
       subtitle = 'Effects Applied to the Governors on a Scaled Basis')

ggsave("../figures/prediction_scaled_governor.png", height = 6, width = 8)

# I make the map for the "flat president" model
plot_usmap(data = fp_new_prediction, regions = "states", values = "trump_wins_state") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = '2020 Presidential Prediction by Ad Spending and Coronavirus Effects',
       subtitle = 'Effects Applied to the President on a Binary Basis')

ggsave("../figures/prediction_flat_president.png", height = 6, width = 8)

# I make the map for the "scaled president" model
plot_usmap(data = sp_new_prediction, regions = "states", values = "trump_wins_state") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = '2020 Presidential Prediction by Ad Spending and Coronavirus Effects',
       subtitle = 'Effects Applied to the President on a Scaled Basis')

ggsave("../figures/prediction_scaled_president.png", height = 6, width = 8)

# I check the electoral votes in each of these cases.

fg_new_prediction %>% 
  group_by(trump_wins_state) %>% 
  summarize(votes = sum(electors))

sg_new_prediction %>% 
  group_by(trump_wins_state) %>% 
  summarize(votes = sum(electors))

fp_new_prediction %>% 
  group_by(trump_wins_state) %>% 
  summarize(votes = sum(electors))

sp_new_prediction %>% 
  group_by(trump_wins_state) %>% 
  summarize(votes = sum(electors))
