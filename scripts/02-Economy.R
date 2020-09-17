#### Economy ####
#### Gov 1347: Election Analysis (2020)
#### TFs: Soubhik Barari, Sun Young Park

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

## install via `install.packages("name")`
library(tidyverse)
library(ggplot2)

## set working directory here
setwd("~/gov1347/election_analytics_blog/scripts")

####----------------------------------------------------------#
#### The relationship between economy and PV ####
####----------------------------------------------------------#

economy_df <- read_csv("../data/econ.csv") 
popvote_df <- read_csv("../data/popvote_1948-2016.csv") 
local_econ_df <- read_csv("../data/local.csv")
electoral_college_df <- read_csv("../data/ec_1952-2020.csv")

dat <- popvote_df %>% 
  filter(incumbent_party == TRUE) %>%
  select(year, winner, pv2p) %>%
  left_join(economy_df %>% filter(quarter == 2))

## scatterplot + line
dat %>%
  ggplot(aes(x=GDP_growth_qt, y=pv2p,
             label=year)) + 
  geom_text() +
  geom_smooth(method="lm", formula = y ~ x) +
  geom_hline(yintercept=50, lty=2) +
  geom_vline(xintercept=0.01, lty=2) + # median
  xlab("Second quarter GDP growth") +
  ylab("Incumbent party's national popular pv2p") +
  theme_bw()

## fit a model
lm_econ <- lm(pv2p ~ GDP_growth_qt, data = dat)
summary(lm_econ)

dat %>%
  ggplot(aes(x=GDP_growth_qt, y=pv2p,
             label=year)) + 
    geom_text(size = 8) +
    geom_smooth(method="lm", formula = y ~ x) +
    geom_hline(yintercept=50, lty=2) +
    geom_vline(xintercept=0.01, lty=2) + # median
    xlab("Q2 GDP growth (X)") +
    ylab("Incumbent party PV (Y)") +
    theme_bw() +
    ggtitle("Y = 49.44 + 2.969 * X") + 
    theme(axis.text = element_text(size = 20),
          axis.title = element_text(size = 24),
          plot.title = element_text(size = 32))

## model fit 

#TODO

## model testing: leave-one-out
outsamp_mod  <- lm(pv2p ~ GDP_growth_qt, dat[dat$year != 2016,])
outsamp_pred <- predict(outsamp_mod, dat[dat$year == 2016,])
outsamp_true <- dat$pv2p[dat$year == 2016] 

## model testing: cross-validation (one run)
years_outsamp <- sample(dat$year, 8)
mod <- lm(pv2p ~ GDP_growth_qt,
          dat[!(dat$year %in% years_outsamp),])

outsamp_pred <- #TODO
  
## model testing: cross-validation (1000 runs)
outsamp_errors <- sapply(1:1000, function(i){
  #TODO
})

hist(outsamp_errors,
     xlab = "",
     main = "mean out-of-sample residual\n(1000 runs of cross-validation)")

## prediction for 2020
GDP_new <- economy_df %>%
    subset(year == 2020 & quarter == 2) %>%
    select(GDP_growth_qt)

predict(lm_econ, GDP_new)

#TODO: predict uncertainty
  
## extrapolation?
##   replication of: https://nyti.ms/3jWdfjp

economy_df %>%
  subset(quarter == 2 & !is.na(GDP_growth1)) %>%
  ggplot(aes(x=year, y=GDP_growth1,
             fill = (GDP_growth1 > 0))) +
  geom_col() +
  xlab("Year") +
  ylab("GDP Growth (Second Quarter)") +
  ggtitle("The percentage decrease in G.D.P. is by far the biggest on record.") +
  theme_bw() +
  theme(legend.position="none",
        plot.title = element_text(size = 12,
                                  hjust = 0.5,
                                  face="bold"))
