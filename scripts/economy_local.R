## Notebook to explore how local economy explains variation 
## in state-level outcomes (extension #3) and how this 
## is heterogeneous b/t parties

library(tidyverse)

setwd("~/Google Drive Harvard/Courses/Gov1347-ElectionAnalytics-2020/Sections-Public/02-Economy")

#####------------------------------------------------------#
#####  Read in and clean data ####
#####------------------------------------------------------#

economy_df <- read_csv("econ.csv")
local_df   <- read_csv("local.csv")
popvote_df <- read_csv("popvote_1948-2016.csv")
pvstate_df <- read_csv("popvote_bystate_1948-2016.csv")

local_df$Q <- ifelse(as.numeric(local_df$Month) %in% 1:3, 1,
                  ifelse(as.numeric(local_df$Month) %in% 4:6, 2, 
                         ifelse(as.numeric(local_df$Month) %in% 7:9, 3, 
                                ifelse(as.numeric(local_df$Month) %in% 10:12, 4, NA))))
economy_df$Q <- economy_df$quarter

## Behavioral model: voters perceive relative *changes* in 
##                   local economic conditions, not overall *baseline* levels.

### Q2-Q3 changes
local_qt <- local_df %>% 
    mutate(State=`State and area`) %>%
    group_by(State) %>%
    arrange(Year, Q) %>%
    mutate(Unemployed_up = Unemployed_prce - lag(Unemployed_prce, n = 1, order_by=Q),
           Unemployed_lag = lag(Unemployed_prce, n = 1, order_by=Q)) %>%
    filter(Year != 1976, Q == 3) %>%
    select(State, Year, Unemployed_up, Unemployed_prce, Unemployed_lag)

### between-year changes
local_yr <- local_df %>% 
    mutate(State=`State and area`) %>%
    group_by(Year, State) %>%
    summarise(Unemployed_prce=mean(Unemployed_prce)) %>%
    ungroup() %>%
    group_by(State) %>%
    mutate(Unemployed_up = Unemployed_prce - lag(Unemployed_prce, n = 1, order_by=Year),
           Unemployed_lag = lag(Unemployed_prce, n = 1, order_by=Year)) %>%
    filter(Year != 1976)


## Merge datasets
pvstate_local <- pvstate_df %>% 
  ##>> filter out missing observations
  filter(year > 1980) %>%
  ##>> one-sided model
  left_join(popvote_df %>% 
              filter(incumbent_party == TRUE), 
            by = "year") %>%
  ##>> merge and clean
  left_join(local_yr, by = c("state" = "State", "year" = "Year")) %>% 
  rename(incparty = party) %>%
  mutate(state_incwin = case_when(incparty == "republican" ~ 
                                    if_else(R_pv2p > D_pv2p,
                                            TRUE, FALSE),
                                  incparty == "democrat" ~
                                    if_else(D_pv2p > R_pv2p,
                                            TRUE, FALSE))) %>% 
  mutate(state_incpv2p = ifelse(incparty == "republican", R_pv2p, D_pv2p)) %>%
  ##>> line up lagged vote for incumbent party
  group_by(state) %>%
  mutate(state_Dpv2p_lag = lag(D_pv2p, n = 1, order_by = year),
         state_Rpv2p_lag = lag(R_pv2p, n = 1, order_by = year)) %>%
  ungroup() %>%
  mutate(state_incpv2p_lag = ifelse(incparty == "republican", 
                                    state_Rpv2p_lag, state_Dpv2p_lag)) %>%
  ##>> merge with Q2 economy indicators
  left_join(economy_df %>% filter(quarter == 2)) %>%
  ##>> select final variables
  select(state, year, incumbent, 
         incparty, state_incwin, state_incpv2p, state_incpv2p_lag,
         Unemployed_up, Unemployed_prce,
         inflation, RDI_growth, GDP_growth_qt)
  
pvstate_local$period <- ifelse(pvstate_local$year %in% 1980:1988, "1980-1988",
                                     ifelse(pvstate_local$year %in% 1992:2000, "1992-2000",
                                            ifelse(pvstate_local$year %in% 2004:2012, "2004-2012", 
                                                   "2016-2020")))

#####------------------------------------------------------#
#####  Describe data ####
#####------------------------------------------------------#

## Bivariate correlations:
## do unemployment increases correlate with incumbent punishment?
cor(pvstate_local$Unemployed_up, pvstate_local$state_incwin, use="pairwise")
cor(pvstate_local$Unemployed_up, pvstate_local$state_incpv2p, use="pairwise")

## Bivariate correlations *by party*:
## is the above stronger for incumbents of one party than another?
{
par(mfrow=c(2,1))
plot(pvstate_local$Unemployed_up[pvstate_local$incparty == "republican"], 
     pvstate_local$state_incpv2p[pvstate_local$incparty == "republican"],
     main = "When Republicans Are\nthe Incumbent Party...",
     xlab="unemployment % increase", ylab="two-party vote-share")
plot(pvstate_local$Unemployed_up[pvstate_local$incparty == "democrat"], 
     pvstate_local$state_incpv2p[pvstate_local$incparty == "democrat"],
     main = "When Democrats Are\nthe Incumbent Party...",
     xlab="unemployment % increase", ylab="two-party vote-share")
}

cor(pvstate_local$Unemployed_up[pvstate_local$incparty == "republican"], 
    pvstate_local$state_incpv2p[pvstate_local$incparty == "republican"], use="pairwise")
cor(pvstate_local$Unemployed_up[pvstate_local$incparty == "democrat"], 
    pvstate_local$state_incpv2p[pvstate_local$incparty == "democrat"], use="pairwise")

#####------------------------------------------------------#
#####  Build model ####
#####------------------------------------------------------#

## Interaction model: differential effects of unemployment *by party*
mod <- lm(state_incpv2p ~ incparty + Unemployed_up, data = pvstate_local)
mod <- lm(state_incpv2p ~ incparty + Unemployed_up + incparty:Unemployed_up, data = pvstate_local)
mod <- lm(state_incpv2p ~ incparty*Unemployed_up, data = pvstate_local)

summary(mod)
plot(mod$model$state_incpv2p, mod$fitted.values, main="interaction model 1")

## Multiple IVs to explain variation (controls)
mod <- lm(state_incpv2p ~ incparty*Unemployed_up + 
                          GDP_growth_qt + RDI_growth + Unemployed_prce +
                          state + state_incpv2p_lag + period, 
          data = pvstate_local)
summary(mod) ## R^2 way good - both blessing (in-sample fit!) and curse (overfitting!)
plot(mod$model$state_incpv2p, mod$fitted.values, main="interaction model 2")

## Agrees with other models of *county-level* unemployment:
## - Wright (2012): jstor.org/stable/pdf/23357704.pdf
## - Burden and Wichoswky (2014): jstor.org/stable/pdf/10.1017/s0022381614000437.pdf

## Always good if your predictive model substantively agrees with 
## other models with a different *unit of analysis*

#####------------------------------------------------------#
#####  Predictions ####
#####------------------------------------------------------#

##TODO: predictions for 2020



