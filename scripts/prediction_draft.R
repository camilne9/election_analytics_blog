library(tidyverse)

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



