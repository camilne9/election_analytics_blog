library(tidyverse)
library(lubridate)
library(zoo)
library(ggthemes)
library(knitr)
library(stargazer)
library(janitor)

setwd("~/gov1347/election_analytics_blog/scripts")

# First I read in the relevant data
pop_vote <- read_csv("../data/popvote_1948-2016.csv") 
state_vote <- read_csv("../data/popvote_bystate_1948-2016.csv")
fedgrants_county_df <- read_csv("../data/fedgrants_bycounty_1988-2008.csv")
fedgrants_state_df <- read_csv("../data/fedgrants_bystate_1988-2008.csv")
ad_campaigns <- read_csv("../data/ad_campaigns_2000-2012.csv")
ad_creative <- read_csv("../data/ad_creative_2000-2012.csv")
ads_2020 <- read_csv("../data/ads_2020.csv")

# First I extract swing state data from the grants dataset
swing_states <- fedgrants_state_df %>% 
  filter(elxn_year == 1) %>% 
  mutate(swing_state = str_detect(state_year_type, "swing")) %>% 
  replace_na(list(swing_state = FALSE)) %>% 
  mutate(state = state_abb) %>% 
  select(year, state, swing_state)

# I combine swing state status data with TV ad spending data
ad_spending <- ad_campaigns %>% 
  mutate(month = month(air_date)) %>% 
  filter(month == 9) %>% 
  group_by(party, state, cycle) %>% 
  summarize(expenses = sum(total_cost)) %>% 
  ungroup() %>% 
  pivot_wider(names_from = party, values_from = expenses) %>% 
  mutate(year = cycle) %>% 
  select(-cycle) %>% 
  left_join(swing_states, by = c('state', 'year')) %>% 
  mutate(swing_state = ifelse(is.na(swing_state), FALSE, swing_state))

# I clean the data to get the difference in spending.
rep_edge <- state_vote %>% 
  mutate(winner = ifelse(D>R, "Safe Democrat States", "Safe Republican States")) %>%
  mutate(state = setNames(state.abb, state.name)[state]) %>% 
  select(-total, -D, -R) %>% 
  right_join(ad_spending, by = c('state', 'year')) %>% 
  filter(!is.na(democrat)) %>% 
  filter(!is.na(republican)) %>% 
  mutate(lean = ifelse(swing_state == FALSE, winner, "Battleground States")) %>% 
  mutate(rep_funding_edge = republican - democrat) %>% 
  #filter(lean == "Democrat") %>% 
  mutate(lean = ifelse(abs(D_pv2p - R_pv2p) < 5, "Battleground States", lean)) %>% 
  filter(!is.na(state)) %>% 
  filter(!is.na(lean))

spending_breakdown <- rep_edge %>% 
  group_by(lean) %>%
  summarize(Republicans = mean(republican), 
            Democrats = mean(democrat),
            rep_sd = sd(republican),
            dem_sd = sd(democrat)) %>% 
  pivot_longer(cols = c(Republicans, Democrats), 
               names_to = 'party', values_to = "avg_spending") %>% 
  mutate(stdev = ifelse(party == "Republicans", rep_sd, dem_sd)) %>% 
  select(-rep_sd, -dem_sd)

# Here I create a bar plot comparing the amount of spending by different parties
# broken down by the competitiveness of states.
spending_breakdown %>% 
  ggplot(aes(x = party, y = avg_spending/10^6, fill = party))+
  geom_col()+ 
  facet_wrap(~ lean)+
# Since the error bars make the meaning of the plot less clear, I am omitting them.
#   geom_errorbar(aes(ymin = avg_spending - stdev, ymax = avg_spending +stdev), width = 0.2)
  labs(title = "Average Spending by Party and Competitiveness of State",
       subtitle = "",
       x = "",
       y = "Spending (in Millions of Dollars)")+
  theme_hc()+
  theme(legend.position = 'None')+
  scale_fill_manual(values = c("blue", "red"))

ggsave("../figures/absolute_spending.png", height = 6, width = 8)

# Here I create a similar graphic that shows PROPORTION of spending in each type of state
# for each party. This adjusts for the difference in total spending.

# First we find the total spending of each party
total_dem <- spending_breakdown %>% 
  filter(party == "Democrats") %>% 
  summarize(total = sum(avg_spending)) %>% 
  pull(total)

total_rep <- spending_breakdown %>% 
  filter(party == "Republicans") %>% 
  summarize(total = sum(avg_spending)) %>% 
  pull(total)
  
# Now we make the plot
spending_breakdown %>% 
  mutate(avg_spending = ifelse(party == "Democrats", 
                               avg_spending/total_dem, avg_spending/total_rep)) %>% 
  ggplot(aes(x = party, y = 100*avg_spending, fill = party))+
  geom_col()+ 
  facet_wrap(~ lean)+
  labs(title = "Proportion of Spending by Party and Competitiveness of State",
       subtitle = "",
       x = "",
       y = "Percent of Total Spending")+
  theme_hc()+
  theme(legend.position = 'None')+
  scale_fill_manual(values = c("blue", "red"))

ggsave("../figures/normalized_spending.png", height = 6, width = 8)

# Now I plot the trend of two party vote share as a function of 
# Republican Spending advantage.
rep_edge %>% 
  ggplot(aes(x = rep_funding_edge/10^6, y = R_pv2p, color = lean))+
  geom_point()+
  geom_smooth(method = "glm", 
              se = FALSE)+
  labs(title = "Republican Two Party Vote Share by Republican Spending Advantage",
       subtitle = "By Competetiveness of State",
       x = "Republican Spending Advantage (Millions of US Dollars)",
       y = "Republican Two Party Vote Share (%)")+
  scale_color_manual(values = c("purple", "darkblue", "red"))+
  theme_minimal()+
  theme(legend.title = element_blank())

ggsave("../figures/republican_spending_advantage.png", height = 6, width = 8)

battleground_data <- rep_edge %>% 
  filter(lean == "Battleground States") %>% 
  mutate(rep_funding_edge = rep_funding_edge)

lm_battleground <- lm(R_pv2p ~ rep_funding_edge, data = battleground_data)
summary(lm_battleground)
  
