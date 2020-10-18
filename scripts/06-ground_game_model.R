library(tidyverse)
library(lubridate)
library(zoo)
library(ggthemes)
library(knitr)
library(stargazer)
library(janitor)
library(usmap)

setwd("~/gov1347/election_analytics_blog/scripts")

# First I read in the relevant data
pop_vote <- read_csv("../data/popvote_1948-2016.csv") 
state_vote <- read_csv("../data/popvote_bystate_1948-2016.csv")
fedgrants_county_df <- read_csv("../data/fedgrants_bycounty_1988-2008.csv")
fedgrants_state_df <- read_csv("../data/fedgrants_bystate_1988-2008.csv")
ad_campaigns <- read_csv("../data/ad_campaigns_2000-2012.csv")
ad_creative <- read_csv("../data/ad_creative_2000-2012.csv")
ads_2020 <- read_csv("../data/ads_2020.csv")
battleground <- read_csv("../data/battleground.csv")
romney <- read_csv("../data/RomneyGroundGame2012.csv")
turnout <- read_csv("../data/turnout_1980-2016.csv")
demographics <- read_csv("../data/demographic_1990-2018.csv")
popvote_bycounty_2012_2016_WI <- read_csv("../data/popvote_bycounty_2012-2016_WI.csv")
local <- read_csv("../data/local.csv")
turnout_demographics <- read_csv("../data/turnout_demographics.csv")
polls_10_17 <- read_csv("../data/updated_polling_10-17.csv")

# I clean the data and find turnout by state in election years for battleground states.  
state_turnout <- turnout %>%
  filter(state != "United States") %>% 
  left_join(state_vote, group_by = c('state', 'year')) %>% 
  filter(year %%4 == 0) %>% 
  mutate(dem_win = (R_pv2p < D_pv2p)) %>% 
  filter(abs(R_pv2p-D_pv2p) < 8) %>% 
  mutate(turnout_pct = as.numeric(sub("%", "", turnout_pct))) %>% 
  mutate(turnout_pct = ifelse(year == 2016, turnout_pct*100, turnout_pct))

# Here I make a histogram of the Democrat wins by turnout percentage. We see that this
# is not useful because we have no information about how common different turnout
# percentages are. Thus, I will make a better plot.
state_turnout %>% 
  # filter(dem_win) %>% 
  ggplot(aes(turnout_pct))+
  geom_histogram(bins = 40)

# I generate a column plot that shows the win rate for Democrats for different 
# turnout percentages
state_turnout %>% 
  mutate(turnout_pct = 5*floor((turnout_pct+2.5)/5)) %>% 
  group_by(turnout_pct) %>% 
  summarize(dem_win_rate = sum(dem_win)/n(), count = n(), wins = sum(dem_win)) %>%
  ggplot(aes(x = turnout_pct, y = 100*dem_win_rate))+
  geom_col()+
  theme_economist()+
  labs(x = "\n Voter Turnout (%)",
       y = "Democratic Win Rate (%) \n",
       title = "Democratic Win Rate by Voter Turnout",
       subtitle = "\n For battleground states from 1980 to 2016")

ggsave("../figures/turnout_vs_winrate.png", height = 6, width = 8)

# We find the population in each election that fall in each demographic.
state_demographics <- demographics %>%
  mutate(White = White*total/100) %>% 
  mutate(Black = Black*total/100) %>% 
  mutate(Indigenous = Indigenous*total/100) %>% 
  mutate(Hispanic = Hispanic*total/100) %>% 
  mutate(Asian = Asian*total/100) %>% 
  group_by(year) %>% 
  summarize(white = sum(White),
            black = sum(Black),
            hispanic = sum(Hispanic),
            other = sum(Asian)+sum(Indigenous)) %>% 
  filter(year %% 4 == 0) %>% 
  pivot_longer(cols = c('white', 'black', 'hispanic', 'other'), names_to = "demographic",
               values_to = "population")

# We find the proportion of the voters that are white by using the population
# and the voting turnout by demographic
national_pv <- turnout_demographics %>% 
  mutate(demographic = str_replace(demographic, "Non-Hispanic White", 'white')) %>% 
  mutate(demographic = str_replace(demographic, "Non-Hispanic Black", 'black')) %>% 
  mutate(demographic = str_replace(demographic, "Hispanic", 'hispanic')) %>% 
  mutate(demographic = str_replace(demographic, "Other", 'other')) %>% 
  right_join(state_demographics, by = c('year', 'demographic')) %>% 
  mutate(voter_count = as.numeric(sub("%", "", turnout))*population/100) %>% 
  select(-turnout, -population) %>% 
  group_by(year) %>% 
  pivot_wider(names_from = demographic, values_from = voter_count) %>% 
  mutate(total_voters = white+ black + hispanic + other) %>%
  mutate(white_proportion = white/total_voters) %>% 
  left_join(pop_vote, by = c('year')) %>% 
  filter(party == 'democrat') %>% 
  select(year, white_proportion, pv2p)

national_pv %>% 
  ggplot(aes(x = white_proportion, y = pv2p))+
  geom_point()+
  geom_smooth(method = "glm", 
                          se = FALSE)+
  theme_minimal()+
  labs(x = "\n Proportion of Voters that were Non-Hispanic Whites",
       y = "Democratic Two Party Popular Vote Share \n",
       title = "Democratic Vote Share by Demographics of Voters",
       subtitle = "Elections from 1992 to 2016 \n")

ggsave("../figures/white_vote_1992.png", height = 6, width = 8)

# Now we create an examine the regression line
lm_national_pv <- lm(pv2p ~ white_proportion, data = national_pv)
summary(lm_national_pv)

# To check robustness, we remove the Clinton elections
national_pv_recent <- national_pv %>% 
  filter(year >= 2000)

# I re-plot the data with the resticted set of years
national_pv_recent %>% 
  ggplot(aes(x = white_proportion, y = pv2p))+
  geom_point()+
  geom_smooth(method = "glm", 
              se = FALSE)+
  theme_minimal()+
  labs(x = "\n Proportion of Voters that were Non-Hispanic Whites",
       y = "Democratic Two Party Popular Vote Share \n",
       title = "Democratic Vote Share by Demographics of Voters",
       subtitle = "Elections from 2000 to 2016 \n")

ggsave("../figures/white_vote_2000.png", height = 6, width = 8)

# I consider the regression line for this case.
lm_national_pv_recent <- lm(pv2p ~ white_proportion, data = national_pv_recent)
summary(lm_national_pv_recent)


# Now we will revisit my prediction from two weeks ago when I explored polling:
# Recall my model:

# model:
# Electoral Prediction = 
# (10 - months until election)/10 * State Poll Prediction + 
# (months until election)/10 * National Poll Prediction

state_polls <- polls_10_17 %>% 
  filter(leading_party == "R") %>% 
  summarize(sum(electors)) %>% 
  deframe()

# Current national polls have Republicans polled at 42.0% and Democrats polled at 52.4%
# We convert to two party share and scale by 538 electoral votes:

national_polls <- 41.8/(41.8+52.4)*538


# Now we define our number of months left
month_left <- 1

# Finally we make a prediction for Trump's electoral vote share:
prediction <- round((10-month_left)/10*state_polls + month_left/10*national_polls)


# I also create a mpa showing the result of the election if the current state polling
# perfectly predicts the result in every state
plot_usmap(data = polls_10_17, regions = "state", values = "leading_party") + 
  scale_fill_manual(values = c("blue", "red"), name = "state winner") +
  theme_void()+
  theme(legend.position = 'None')+
  labs(title = "2020 Electoral Map Predicted by Polling",
       subtitle = "Polling from 10/17")

ggsave("../figures/polling_10_17.png", height = 6, width = 8)
