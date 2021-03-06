library(tidyverse)
library(lubridate)
library(zoo)
library(ggthemes)
library(knitr)
library(stargazer)

setwd("~/gov1347/election_analytics_blog/scripts")

# First I read in the relevant data
pop_vote <- read_csv("../data/popvote_1948-2016.csv") 
state_vote <- read_csv("../data/popvote_bystate_1948-2016.csv")
fedgrants_county_df <- read_csv("../data/fedgrants_bycounty_1988-2008.csv")
fedgrants_state_df <- read_csv("../data/fedgrants_bystate_1988-2008.csv")

# I want to find the increase in federal grants in each state between each election
# so I compare the grant amount to the previous grant amount.
grant_increase <- fedgrants_state_df %>% 
  filter(elxn_year == 1) %>% 
  group_by(state_abb) %>% 
  mutate(prev_grant = lag(grant_mil, order_by = year)) %>% 
  mutate(grant_increase = grant_mil - prev_grant) %>% 
  ungroup()

# I combine all the data to look at national results (including incumbency), 
# state specific results, and grants data. I make columns of the previous
# pop vote in each state so we can compare CHANGE in popular vote
full_popvote <- pop_vote %>% 
  left_join(state_vote, by = c("year")) %>% 
  mutate(state_abb = setNames(state.abb, state.name)[state]) %>% 
  right_join(grant_increase, by = c('state_abb', 'year')) %>% 
  mutate(swing_state = str_detect(state_year_type, "swing")) %>% 
  replace_na(list(swing_state = FALSE)) %>% 
  filter(party == 'republican') %>% 
  group_by(state) %>% 
  mutate(prev_dem_vote = lag(D_pv2p, order_by = year)) %>% 
  mutate(prev_rep_vote = lag(R_pv2p, order_by = year)) %>% 
  ungroup()

# I find the change in popular vote between elections for each state, and find 
# what change applied for the incumbent party specifically.
selected_data <- full_popvote %>% 
  mutate(dem_increase = D_pv2p - prev_dem_vote) %>% 
  mutate(rep_increase = R_pv2p - prev_rep_vote) %>% 
  select(year, party, incumbent, incumbent_party, state, 
         grant_increase, swing_state, rep_increase, dem_increase) %>% 
  filter(year > 1984) %>% 
  mutate(incumbent_increase = incumbent_party*rep_increase + (1-incumbent_party)*dem_increase)


# I make plots of the overall trend, the trend broken down by swing and non-swing,
# and the trend broken down by party.

# Here's the plot for the overall trend.
selected_data %>% 
  ggplot(aes(x = grant_increase, y = incumbent_increase))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)+
  labs(title = "Incumbent Party Vote Share Growth by Federal Grant Growth",
       subtitle = "For each state from 1988 to 2008",
       x = "Increase in Federal Grants to the State \n (in Millions of US Dollars)",
       y = "Increase in Vote Share of Incumbent Party")+
  theme_solarized_2()

ggsave("../figures/grants_vs_votes.png", height = 6, width = 8)

# Here's the plot broken down by party.
selected_data %>% 
  mutate(incumbent_party = str_replace(incumbent_party, "TRUE", "Republican")) %>% 
  mutate(incumbent_party = str_replace(incumbent_party, "FALSE", "Democrat")) %>% 
  ggplot(aes(x = grant_increase, y = incumbent_increase, color = incumbent_party))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)+
  labs(title = "Incumbent Party Vote Share Growth by Federal Grant Growth",
       subtitle = "For each state from 1988 to 2008, by Incumbent Party",
       x = "Increase in Federal Grants to the State  \n (in Millions of US Dollars)",
       y = "Increase in Vote Share of Incumbent Party")+
  theme_solarized_2()+
  scale_colour_manual(values = c("darkblue", "red"))+
  theme(legend.title = element_blank())

ggsave("../figures/grants_party.png", height = 6, width = 8)

# Here's the plot broken down by swing and non-swing states.
selected_data %>% 
  mutate(swing_state = str_replace(swing_state, "TRUE", "Swing State")) %>% 
  mutate(swing_state = str_replace(swing_state, "FALSE", "Non-Swing State")) %>% 
  ggplot(aes(x = grant_increase, y = incumbent_increase, color = swing_state))+
  geom_point()+
  geom_smooth(method = 'lm', se = 0)+
  labs(title = "Incumbent Party Vote Share Growth by Federal Grant Growth",
       subtitle = "For each state from 1988 to 2008, by Swing State Status",
       x = "Increase in Federal Grants to the State \n (in Millions of US Dollars)",
       y = "Increase in Vote Share of Incumbent Party")+
  theme_solarized_2()+
  scale_colour_manual(values = c("darkgreen", "purple"))+
  theme(legend.title = element_blank())

ggsave("../figures/grants_swing.png", height = 6, width = 8)

# Now I explicitly find the linear regression of each of the relevant cases.
swing_state <- selected_data %>% 
  filter(swing_state)
lm_swing <- lm(incumbent_increase ~ grant_increase, data = swing_state)
summary(lm_swing)

non_swing_state <- selected_data %>% 
  filter(swing_state == FALSE)
lm_nonswing <- lm(incumbent_increase ~ grant_increase, data = non_swing_state)
summary(lm_nonswing)

republican_incumbent <- selected_data %>% 
  filter(incumbent)
lm_republican_incumbent <- lm(incumbent_increase ~ grant_increase, data = republican_incumbent)
summary(lm_republican_incumbent)

democrat_incumbent <- selected_data %>% 
  filter(incumbent == FALSE)
lm_democrat_incumbent <- lm(incumbent_increase ~ grant_increase, data = democrat_incumbent)
summary(lm_democrat_incumbent)

# Observing that the r-squareds for these regressions are very low, we conclude that it 
# would be unreasonable to make predictions based on these regression lines.
