library(tidyverse)
library(janitor)
library(usmap)
library(ggthemes)
library(gt)


setwd("~/gov1347/election_analytics_blog/scripts")

# I read in the data
results <- read_csv("../data/results2020_11-11.csv")
final_prediction <- read_csv("../data/final_prediction.csv")
all_results <- read_csv("../data/popvote_bystate_1948-2020.csv")
electors <- read_csv("../data/battleground.csv")
enos_results <- read_csv("../data/StateResults2020.csv") %>% 
  clean_names()
county_demog <- read_csv("../data/demog_county_1990-2018.csv")
county_results_2020 <- read_csv("../data/CountyResults2020.csv") %>% 
  clean_names()
county_results_2016 <- read_csv("../data/popvote_bycounty_2000-2016.csv")
demographics <- read_csv("../data/demographic_1990-2018.csv")


# I create a cleaner version of the results that Professor Enos provided
# including two party vote share
clean_results <- enos_results %>% 
  mutate(state = geographic_name) %>% 
  filter(state != "name") %>% 
  mutate(trump_2p = 100*as.integer(donald_j_trump)/(as.integer(donald_j_trump)+as.integer(joseph_r_biden_jr))) %>% 
  mutate(biden_2p = 100*as.integer(joseph_r_biden_jr)/(as.integer(donald_j_trump)+as.integer(joseph_r_biden_jr))) %>%
  mutate(trump_winner = (trump_2p > biden_2p)) %>% 
  select(state, trump_2p, biden_2p, trump_winner, fips)

# I do the same for the county level data
clean_county <- county_results_2020 %>%
  mutate(county = geographic_name) %>% 
  filter(geographic_name != "name") %>% 
  mutate(trump_2p = 100*as.integer(donald_j_trump)/(as.integer(donald_j_trump)+as.integer(joseph_r_biden_jr))) %>% 
  mutate(biden_2p = 100*as.integer(joseph_r_biden_jr)/(as.integer(donald_j_trump)+as.integer(joseph_r_biden_jr))) %>%
  mutate(rep = 100*as.integer(donald_j_trump)/as.integer(total_vote)) %>% 
  mutate(dem = 100*as.integer(joseph_r_biden_jr)/as.integer(total_vote)) %>% 
  mutate(trump_winner = (trump_2p > biden_2p)) %>%
  mutate(fips = as.double(fips)) %>% 
  select(county, trump_2p, biden_2p, trump_winner, fips, rep, dem, total_vote)

# I merge the 2016 data into the 2020 data set
full_county <- county_results_2016 %>% 
  filter(year == 2016) %>% 
  left_join(clean_county, by = "fips") %>% 
  mutate(D_margin_2016 = D_win_margin) %>% 
  mutate(D_margin_2020 = dem-rep) %>% 
  mutate(county = county.y) %>%
  mutate(fips_county = fips %% 1000) %>% 
  select(-year, -D_win_margin, -county.x, -county.y)
  
# I merge the demographic data into the county data set. I use the 2016
# demographic data as a proxy for 2020 since I do not have 2020 data.
results_demog <- county_demog %>% 
  filter(year == 2016) %>% 
  mutate(fips_county = as.double(fips_county)) %>%
  mutate(state_abb = state) %>% 
  select(-year) %>%
  left_join(full_county, by = c("fips_county", "state_abb")) %>% 
  select(state_abb, fips, fips_county, Hispanic, 
         total, total_vote, D_margin_2016, D_margin_2020, county) %>% 
  filter(!is.na(D_margin_2016)) %>% 
  filter(!is.na(D_margin_2020)) %>% 
  mutate(total_vote = as.double(total_vote)) %>% 
  mutate(state = state_abb) %>% 
  select(-state_abb)

# I check that all of the counties have populations bigger than the
# number of votes as a sort of dummy check
results_demog %>% 
  filter(total < total_vote)
# I see one county that violates this, but since the census data is not as 
# recent as the 

# I see which candidate wins in each state as another check
check_results <- results_demog %>% 
  group_by(state) %>% 
  summarize(vote_margin = sum(total_vote*D_margin_2020)) %>%
  ungroup() %>% 
  mutate(trump_win = (vote_margin < 0))

# I plot the results.
plot_usmap(data = check_results, regions = "states", values = "trump_win") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "State Map from County Data",
       subtitle = "",
       caption = "(Alaska County Data Unavailable)")
# I do not have Alaska county data, but all other states match the actual
# result, and the lack of Alaska data does not dwindle my confidence in 
# the validity of the data I do have and I have enough data to test the 
# relevant media narrative.

plot_usmap(data = results_demog,
             regions = "counties", values = "Hispanic",
           include = c("AZ")
             # c(4001,4003,4005,4007,4009,4011,
             #           4012,4013,4015,4017,4019,4021,4023,
             #           4025,4027)
           ) + 
  scale_fill_gradient2(
    name = "Percentage \n Hispanic"
  ) +
  theme_void()+
  labs(title = "Percent Hispanic by County",
       subtitle = "In Arizona")

plot_usmap(data = results_demog %>% 
             mutate(change = D_margin_2020-D_margin_2016),
           regions = "counties", values = "change",
           include = c("AZ")
           # c(4001,4003,4005,4007,4009,4011,
           #           4012,4013,4015,4017,4019,4021,4023,
           #           4025,4027)
) + 
  scale_fill_gradient2(
    name = "Change in \n Margin"
  ) +
  theme_void()+
  labs(title = "Change in Democratic Margin by County",
       subtitle = "In Arizona")


# I plot the results.
plot_usmap(data = check_results, regions = "states", values = "trump_win") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "State Map from County Data",
       subtitle = "",
       caption = "(Alaska County Data Unavailable)")
# I do not have Alaska county data, but all other states match the actual
# result, and the lack of Alaska data does not dwindle my confidence in 
# the validity of the data I do have and I have enough data to test the 
# relevant media narrative.

plot_usmap(data = results_demog,
           regions = "counties", values = "Hispanic",
           include = c("FL")
           # c(4001,4003,4005,4007,4009,4011,
           #           4012,4013,4015,4017,4019,4021,4023,
           #           4025,4027)
) + 
  scale_fill_gradient2(
    name = "Percentage \n Hispanic"
  ) +
  theme_void()+
  labs(title = "Percent Hispanic by County",
       subtitle = "In Florida")

plot_usmap(data = results_demog %>% 
             mutate(change = D_margin_2020-D_margin_2016),
           regions = "counties", values = "change",
           include = c("FL")
           # c(4001,4003,4005,4007,4009,4011,
           #           4012,4013,4015,4017,4019,4021,4023,
           #           4025,4027)
) + 
  scale_fill_gradient2(
    name = "Change in \n Margin"
  ) +
  theme_void()+
  labs(title = "Change in Democratic Margin by County",
       subtitle = "In Florida")

results_demog %>% 
  mutate(change = D_margin_2020-D_margin_2016) %>% 
  ggplot(aes(x = Hispanic, y = change, color = state))+
  geom_point()+
  theme(legend.position = 'None')

results_demog %>% 
  mutate(change = D_margin_2020-D_margin_2016) %>% 
  ggplot(aes(x = Hispanic, y = change))+
  geom_point()+
  labs(title = "Change in Democratic Margin \n by Percentage Hispanic",
       subtitle = "State by State")+
  theme(legend.position = 'None')+
  facet_wrap(~state)+
  theme_minimal()

# I consider which states have the largest Hispanic populations.
demographics %>% 
  filter(year == 2016) %>%
  select(state, Hispanic) %>% 
  arrange(desc(Hispanic)) %>% 
  head(10) %>% 
  gt()

results_demog %>% 
  mutate(State = state) %>% 
  filter(State %in% c("AZ", "FL", "TX", "NV", "NM", "CA")) %>%
  mutate(change = D_margin_2020-D_margin_2016) %>% 
  ggplot(aes(x = Hispanic, y = change, color = State))+
  geom_point()+
  labs(title = "Change in Democratic Margin \n by Percentage Hispanic",
       subtitle = "State by State",
       x = "Percent of Population that is Hispanic",
       y = "Change in Democratic Margin")+
  facet_wrap(~state)+
  theme_minimal()+
  theme(legend.position = 'None')

 