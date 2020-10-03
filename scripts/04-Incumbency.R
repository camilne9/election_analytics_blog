#### Incumbency ####
#### Gov 1347: Election Analysis (2020)
#### TFs: Soubhik Barari, Sun Young Park

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

## install via `install.packages("name")`
library(tidyverse)
library(knitr)
library(stargazer)

## set working directory here
setwd("~")

####----------------------------------------------------------#
#### The incumbency advantage: simple descriptive statistics ####
####----------------------------------------------------------#

popvote_df <- read_csv("popvote_1948-2016.csv")

# How many post-war elections where incumbent president won?

popvote_df %>%
  filter(winner) %>%
  select(year, winparty = party, wincand = candidate) %>%
  mutate(winparty_last = lag(winparty, order_by = year),
         wincand_last  = lag(wincand,  order_by = year)) %>%
  mutate(reelect.president = wincand_last == wincand) %>%
  filter(year > 1948) %>%
  group_by(reelect.president) %>% 
  summarise(n = n()) %>% 
  as.data.frame() %>%
  kable(format = "latex")

# How many post-war elections where incumbent party won?

popvote_df %>%
  filter(winner) %>%
  select(year, winparty = party, wincand = candidate) %>%
  mutate(winparty_last = lag(winparty, order_by = year),
         wincand_last  = lag(wincand,  order_by = year)) %>%
  mutate(reelect.party = winparty_last == winparty) %>%
  filter(year > 1948) %>%
  group_by(reelect.party) %>% 
  summarise(n = n()) %>% 
  as.data.frame() %>%
  kable(format = "pipe")

# How many post-war elections where winner served in previous administrations?

table(`prev.admin` = popvote_df$prev_admin[popvote_df$winner]) %>%
  kable(format = "rst")

####----------------------------------------------------------#
#### The incumbency advantage: Presidential Pork 
#### - federal grant ####
####----------------------------------------------------------#

fedgrants_state_df <- read_csv("fedgrants_bystate_1988-2008.csv")

# What strategy do presidents pursue?

fedgrants_state_df %>%
  filter(!is.na(state_year_type)) %>%
  group_by(state_year_type) %>%
  summarise(mean=mean(grant_mil, na.rm=T), se=sd(grant_mil, na.rm=T)/sqrt(n())) %>%
  ggplot(aes(x=state_year_type, y=mean, ymin=mean-1.96*se, ymax=mean+1.96*se)) +
  coord_flip() +
  geom_bar(stat="identity") +
  geom_errorbar(width=.2) +
  xlab("type of state + year") + ylab("federal grant spending (millions of dollars)") +
  theme_minimal() + 
  theme(axis.title = element_text(size=20),
        axis.text = element_text(size=15))

# Do presidents strategize for their successor also?

fedgrants_state_df %>%
  filter(!is.na(state_year_type2)) %>%
  group_by(state_year_type2) %>%
  summarise(mean=mean(grant_mil, na.rm=T), se=sd(grant_mil, na.rm=T)/sqrt(n())) %>%
  ggplot(aes(x=state_year_type2, y=mean, ymin=mean-1.96*se, ymax=mean+1.96*se)) +
  coord_flip() +
  geom_bar(stat="identity") +
  geom_errorbar(width=.2) +
  xlab("type of state + year") + ylab("federal grant spending (millions of dollars)") +
  theme_minimal() + 
  theme(axis.title = element_text(size=20),
        axis.text = element_text(size=15))

## the effect of federal grant (at the county level)

fedgrants_county_df <- read_csv("fedgrants_bycounty_1988-2008.csv")

# McCain, PA (2008)

fedgrants_county_df %>%
  filter(year == 2008 & state_abb == "PA") %>% 
  ggplot(aes(x=dpct_grants, y=dvoteswing_inc, label=county)) +
  geom_vline(xintercept=0, lty=2) +
  geom_hline(yintercept=0, lty=2) +
  geom_smooth(method="lm") +
  xlab("% change in federal grant spending") +
  ylab("% change in incumbent vote-swing") +
  geom_text() +
  theme_classic() + 
  theme(axis.title = element_text(size=20),
        axis.text = element_text(size=15))

# Bush, FL (2004)

fedgrants_county_df %>%
  filter(year == 2004 & state_abb == "FL") %>% 
  ggplot(aes(x=dpct_grants, y=dvoteswing_inc, label=county)) +
  geom_vline(xintercept=0, lty=2) +
  geom_hline(yintercept=0, lty=2) +
  geom_smooth(method="lm") +
  xlab("% change in federal grant spending") +
  ylab("% change in incumbent vote-swing") +
  geom_text() +
  theme_classic() + 
  theme(axis.title = element_text(size=20),
        axis.text = element_text(size=15))

# Gore, TX (2000)

fedgrants_county_df %>%
  filter(year == 2000 & state_abb == "TX") %>%
  ggplot(aes(x=dpct_grants, y=dvoteswing_inc, label=county)) +
  geom_vline(xintercept=0, lty=2) +
  geom_hline(yintercept=0, lty=2) +
  geom_smooth(method="lm") +
  xlab("% change in federal grant spending") +
  ylab("% change in incumbent vote-swing") +
  geom_text() +
  theme_classic() + 
  theme(axis.title = element_text(size=20),
        axis.text = element_text(size=15))

# Gore, VT (2008)

fedgrants_county_df %>%
  filter(year == 2008 & state_abb == "VT") %>%
  ggplot(aes(x=dpct_grants, y=dvoteswing_inc, label=county)) +
  geom_vline(xintercept=0, lty=2) +
  geom_hline(yintercept=0, lty=2) +
  geom_smooth(method="lm") +
  xlab("% change in federal grant spending") +
  ylab("% change in incumbent vote-swing") +
  geom_text() +
  theme_classic() + 
  theme(axis.title = element_text(size=20),
        axis.text = element_text(size=15))



