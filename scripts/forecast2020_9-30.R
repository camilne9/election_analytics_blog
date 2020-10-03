library(tidyverse)
library(ggplot2)

#####------------------------------------------------------#
##### Read and merge data ####
#####------------------------------------------------------#


popvote_df    <- read_csv("popvote_1948-2016.csv")
pvstate_df    <- read_csv("popvote_bystate_1948-2016.csv")
economy_df    <- read_csv("econ.csv")
approval_df   <- read_csv("approval_gallup_1941-2020.csv")
pollstate_df  <- read_csv("pollavg_bystate_1968-2016.csv")
fedgrants_df  <- read_csv("fedgrants_bystate_1988-2008.csv")

#####------------------------------------------------------#
#####  Time-for-change model ####
#####------------------------------------------------------#

tfc_df <- popvote_df %>%
  filter(incumbent_party) %>%
  select(year, candidate, party, pv, pv2p, incumbent) %>%
  inner_join(
    approval_df %>% 
      group_by(year, president) %>% 
      slice(1) %>% 
      mutate(net_approve=approve-disapprove) %>%
      select(year, incumbent_pres=president, net_approve, poll_enddate),
    by="year"
  ) %>%
  inner_join(
    economy_df %>%
      filter(quarter == 2) %>%
      select(GDP_growth_qt, year),
    by="year"
  )

## TODO:

## - fit 

## - evaluate

## - compare to previous models

