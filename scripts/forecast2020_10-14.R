library(tidyverse)
library(ggplot2)
library(statebins)

setwd("~/Google Drive Harvard/Courses/Gov1347-ElectionAnalysis-2020/Sections-Internal")

#####------------------------------------------------------#
##### Read and merge data ####
#####------------------------------------------------------#

demog <- read_csv("demographic_1990-2018.csv")
pvstate_df    <- read_csv("popvote_bystate_1948-2016.csv")
pollstate_df  <- read_csv("pollavg_bystate_1968-2016.csv")
pvstate_df$state <- state.abb[match(pvstate_df$state, state.name)]
pollstate_df$state <- state.abb[match(pollstate_df$state, state.name)]

dat <- pvstate_df %>% 
  full_join(pollstate_df %>% 
              filter(weeks_left == 3) %>% 
              group_by(year,party,state) %>% 
              summarise(avg_poll=mean(avg_poll)),
            by = c("year" ,"state")) %>%
  left_join(demog %>%
              select(-c("total")),
            by = c("year" ,"state"))

dat$region <- state.division[match(dat$state, state.abb)]
demog$region <- state.division[match(demog$state, state.abb)]

dat_change <- dat %>%
  group_by(state) %>%
  mutate(Asian_change = Asian - lag(Asian, order_by = year),
         Black_change = Black - lag(Black, order_by = year),
         Hispanic_change = Hispanic - lag(Hispanic, order_by = year),
         Indigenous_change = Indigenous - lag(Indigenous, order_by = year),
         White_change = White - lag(White, order_by = year),
         Female_change = Female - lag(Female, order_by = year),
         Male_change = Male - lag(Male, order_by = year),
         age20_change = age20 - lag(age20, order_by = year),
         age3045_change = age3045 - lag(age3045, order_by = year),
         age4565_change = age4565 - lag(age4565, order_by = year),
         age65_change = age65 - lag(age65, order_by = year)
  )

#####------------------------------------------------------#
#####  Proposed models ####
#####------------------------------------------------------#

mod_demog_change <- lm(D_pv2p ~ Black_change + Hispanic_change + Asian_change +
                         Female_change +
                         age3045_change + age4565_change + age65_change +
                         as.factor(region), data = dat_change)

stargazer(mod_demog_change, header=FALSE, type='latex', no.space = TRUE,
          column.sep.width = "3pt", font.size = "scriptsize", single.row = TRUE,
          keep = c(1:7, 62:66), omit.table.layout = "sn",
          title = "The electoral effects of demographic change (across states)")

#####------------------------------------------------------#
##### How would our forecast change if there's a Latino surge for Democrats in 2020?
#####------------------------------------------------------#

# new data for 2020
demog_2020 <- subset(demog, year == 2018)
demog_2020 <- as.data.frame(demog_2020)
rownames(demog_2020) <- demog_2020$state
demog_2020 <- demog_2020[state.abb, ]

demog_2020_change <- demog %>%
  filter(year %in% c(2016, 2018)) %>%
  group_by(state) %>%
  mutate(Asian_change = Asian - lag(Asian, order_by = year),
         Black_change = Black - lag(Black, order_by = year),
         Hispanic_change = Hispanic - lag(Hispanic, order_by = year),
         Indigenous_change = Indigenous - lag(Indigenous, order_by = year),
         White_change = White - lag(White, order_by = year),
         Female_change = Female - lag(Female, order_by = year),
         Male_change = Male - lag(Male, order_by = year),
         age20_change = age20 - lag(age20, order_by = year),
         age3045_change = age3045 - lag(age3045, order_by = year),
         age4565_change = age4565 - lag(age4565, order_by = year),
         age65_change = age65 - lag(age65, order_by = year)
  ) %>%
  filter(year == 2018)
demog_2020_change <- as.data.frame(demog_2020_change)
rownames(demog_2020_change) <- demog_2020_change$state
demog_2020_change <- demog_2020_change[state.abb, ]

# prediction
predict(mod_demog_change, newdata = demog_2020_change) +
  (1.28-0.64)*demog_2020$Hispanic

his_original <- data.frame(pred = predict(mod_demog, newdata = demog_2020),
                           state = state.abb)
his1 <- data.frame(pred = predict(mod_demog, newdata = demog_2020) +
                     (1.28-0.64)*demog_2020$Hispanic,
                   state = state.abb)

plot_original <- his_original %>%  ##`statebins` needs state to be character, not factor!
  mutate(state = as.character(state)) %>%
  ggplot(aes(state = state, fill = (pred >= 50))) +
  geom_statebins() +
  theme_statebins() +
  labs(title = "2020 Presidential Election Prediction",
       subtitle = "historical Hispanic demographic change effect (0.64)",
       fill = "") +
  theme(legend.position = "none")

plot_1 <- his1 %>% 
  mutate(state = as.character(state)) %>% ##`statebins` needs state to be character, not factor!
  ggplot(aes(state = state, fill = (pred >= 50))) +
  geom_statebins() +
  theme_statebins() +
  labs(title = "2020 Presidential Election Prediction",
       subtitle = "hypothetical Hispanic demographic change surge (1.28)",
       fill = "") +
  theme(legend.position = "none")

plot_grid(plot_original, plot_1)
