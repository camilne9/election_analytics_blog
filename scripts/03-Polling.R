#### Polling ####
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
#### Quantitatively describing the polls ####
#### - How do polls fluctuate across state, time, and year?
####----------------------------------------------------------#

poll_df <- read_csv("../data/pollavg_1968-2016.csv")

####------- 2016 poll average across time ------ ####

poll_df %>%
  filter(year == 2016) %>%
  ggplot(aes(x = poll_date, y = avg_support, colour = party)) +
    geom_point(size = 1) +
    geom_line() +
    scale_x_date(date_labels = "%b, %Y") +
    scale_color_manual(values = c("blue","red"), name = "") +
    ylab("polling approval average on date") + xlab("") +
    theme_classic()

## DNC & RNC bump in 2016:

poll_df %>%
  filter(year == 2016) %>%
  ggplot(aes(x = poll_date, y = avg_support, colour = party)) +
    geom_rect(xmin=as.Date("2016-07-18"), xmax=as.Date("2016-07-21"), ymin=0, ymax=41, alpha=0.1, colour=NA, fill="grey") +
    annotate("text", x=as.Date("2016-07-15"), y=37.8, label="RNC", size=4) +
    geom_rect(xmin=as.Date("2016-07-25"), xmax=as.Date("2016-07-28"), ymin=42, ymax=100, alpha=0.1, colour=NA, fill="grey") +
    annotate("text", x=as.Date("2016-08-02"), y=47, label="DNC", size=4) +

    geom_point(size = 1) +
    geom_line() +

    scale_x_date(date_labels = "%b, %Y") +
    scale_color_manual(values = c("blue","red"), name = "") +
    ylab("polling approval average on date") + xlab("") +
    theme_classic()

## 'Game-changers' in 2016:

poll_df %>%
  filter(year == 2016) %>%
  ggplot(aes(x = poll_date, y = avg_support, colour = party)) +
    geom_rect(xmin=as.Date("2016-07-18"), xmax=as.Date("2016-07-21"), ymin=0, ymax=41, alpha=0.1, colour=NA, fill="grey") +
    annotate("text", x=as.Date("2016-07-15"), y=37.8, label="RNC", size=4) +
    geom_rect(xmin=as.Date("2016-07-25"), xmax=as.Date("2016-07-28"), ymin=42, ymax=100, alpha=0.1, colour=NA, fill="grey") +
    annotate("text", x=as.Date("2016-08-02"), y=47, label="DNC", size=4) +
  
    geom_point(size = 1) +
    geom_line() +
  
    geom_segment(x=as.Date("2016-04-19"), xend=as.Date("2016-04-19"),y=0,yend=41, lty=2, color="grey", alpha=0.4) +
    annotate("text", x=as.Date("2016-04-05"), y=38, label="Trump wins\nNY primary", size=3) +
    geom_segment(x=as.Date("2016-04-26"), xend=as.Date("2016-04-26"), y=0, yend=41, lty=2, color="grey", alpha=0.4) +
    annotate("text", x=as.Date("2016-05-02"), y=39, label="...and CT,DE,\nMD,PA,RI", size=3) +

    geom_segment(x=as.Date("2016-09-26"), xend=as.Date("2016-09-26"),y=43,yend=100, lty=2, color="grey", alpha=0.4) +
      annotate("text", x=as.Date("2016-09-26"), y=45.7, label="First debate\n'won' by Hillary", size=3) +
    geom_segment(x=as.Date("2016-10-06"), xend=as.Date("2016-10-06"),y=0,yend=40.2, lty=2, color="grey", alpha=0.4) +
      annotate("text", x=as.Date("2016-10-06"), y=39, label="Billy Bush tape", size=3) +
    geom_segment(x=as.Date("2016-10-28"), xend=as.Date("2016-10-28"),y=46,yend=100, lty=2, color="grey", alpha=0.4) +
        annotate("text", x=as.Date("2016-10-28"), y=48, label="Comey annonunces\ninvestigation\nof new emails", size=3) +
      scale_x_date(date_labels = "%b, %Y") +
    scale_color_manual(values = c("blue","red"), name = "") +
    ylab("polling approval average on date") + xlab("") +
    theme_classic()

## 'Game-changers' in 2016 that weren't poll-changers:

poll_df %>%
    filter(year == 2016) %>%
    ggplot(aes(x = poll_date, y = avg_support, colour = party)) +
    geom_rect(xmin=as.Date("2016-07-18"), xmax=as.Date("2016-07-21"), ymin=0, ymax=41, alpha=0.1, colour=NA, fill="grey") +
    annotate("text", x=as.Date("2016-07-15"), y=37.8, label="RNC", size=4) +
    geom_rect(xmin=as.Date("2016-07-25"), xmax=as.Date("2016-07-28"), ymin=42, ymax=100, alpha=0.1, colour=NA, fill="grey") +
    annotate("text", x=as.Date("2016-08-02"), y=47, label="DNC", size=4) +
    
    geom_point(size = 1) +
    geom_line() +
    
    geom_segment(x=as.Date("2016-04-19"), xend=as.Date("2016-04-19"),y=0,yend=41, lty=2, color="grey", alpha=0.4) +
    annotate("text", x=as.Date("2016-04-05"), y=38, label="Trump wins\nNY primary", size=3) +
    geom_segment(x=as.Date("2016-04-26"), xend=as.Date("2016-04-26"), y=0, yend=41, lty=2, color="grey", alpha=0.4) +
    annotate("text", x=as.Date("2016-05-02"), y=39, label="...and CT,DE,\nMD,PA,RI", size=3) +
    geom_segment(x=as.Date("2016-05-26"), xend=as.Date("2016-05-26"), y=0, yend=43.3, lty=2, color="grey", alpha=0.4) +
    annotate("text", x=as.Date("2016-05-26"), y=41, label="Trump secures\nnomination\n(?)", size=3) +
    geom_segment(x=as.Date("2016-07-05"), xend=as.Date("2016-07-05"),y=43.2,yend=100, lty=2, color="grey", alpha=0.4) +
    annotate("text", x=as.Date("2016-07-01"), y=45.7, label="Comey vindicates\nHillary's emails\n(?)", size=3) +
    geom_segment(x=as.Date("2016-09-26"), xend=as.Date("2016-09-26"),y=43,yend=100, lty=2, color="grey", alpha=0.4) +
    annotate("text", x=as.Date("2016-09-26"), y=45.7, label="First debate\n'won' by Hillary", size=3) +
    geom_segment(x=as.Date("2016-10-06"), xend=as.Date("2016-10-06"),y=0,yend=40.2, lty=2, color="grey", alpha=0.4) +
    annotate("text", x=as.Date("2016-10-06"), y=39, label="Billy Bush tape", size=3) +
    geom_segment(x=as.Date("2016-10-28"), xend=as.Date("2016-10-28"),y=46,yend=100, lty=2, color="grey", alpha=0.4) +
    annotate("text", x=as.Date("2016-10-28"), y=48, label="Comey annonunces\ninvestigation\nof new emails", size=3) +
    scale_x_date(date_labels = "%b, %Y") +
    scale_color_manual(values = c("blue","red"), name = "") +
    ylab("polling approval average on date") + xlab("") +
    theme_classic()

####------- 2088 poll average across time ------ ####

## 'Game-changers and bumps in the 1988 campaigns:

poll_df %>%
    filter(year == 1988) %>%
    ggplot(aes(x = poll_date, y = avg_support, colour = party)) +
    geom_rect(xmin=as.Date("1988-07-18"), xmax=as.Date("1988-07-21"), ymin=47, ymax=100, alpha=0.1, colour=NA, fill="grey") +
    annotate("text", x=as.Date("1988-07-17"), y=50, label="DNC", size=4) +
    geom_rect(xmin=as.Date("1988-08-15"), xmax=as.Date("1988-08-18"), ymin=0, ymax=44, alpha=0.1, colour=NA, fill="grey") +
    annotate("text", x=as.Date("1988-08-18"), y=40, label="RNC", size=4) +
    
    geom_point(size = 1) +
    geom_line() + 
    
    geom_segment(x=as.Date("1988-09-13"), xend=as.Date("1988-09-13"),y=49,yend=100, lty=2, color="grey", alpha=0.4) +
    annotate("text", x=as.Date("1988-09-13"), y=52, label="Tank gaffe\n(?)", size=4) +
    annotate("text", x=as.Date("1988-09-21"), y=57, label="Willie Horton ad\n(?)", size=4) +
    geom_segment(x=as.Date("1988-09-21"), xend=as.Date("1988-09-21"),y=49,yend=100, lty=2, color="grey", alpha=0.4) +
    annotate("text", x=as.Date("1988-10-15"), y=64, label="First debate\n(death\npenalty\ngaffe)", size=3) +
    geom_segment(x=as.Date("1988-10-15"), xend=as.Date("1988-10-15"),y=49,yend=100, lty=2, color="grey", alpha=0.4) +
    scale_x_date(date_labels = "%b, %Y") +
    scale_color_manual(values = c("blue","red"), name = "") +
    ylab("polling approval average on date") + xlab("") +
    theme_classic()

####----------------------------------------------------------#
#### Describing the relationship between polls and election outcomes ####
#### - How early can the polls predict election results?
####----------------------------------------------------------#

## Does the November poll predict the election?

popvote_df <- read_csv("../datasets/popvote_1948-2016.csv")

pollnov_df <- poll_df %>%
  group_by(year, party) %>%
  top_n(1, poll_date)

pollnov_vote_margin_df <- pollnov_df %>%
  left_join(popvote_df, by = c("year"="year", "party"="party")) %>%
  group_by(year) %>% arrange(-winner) %>% 
  summarise(pv2p_margin=first(pv2p)-last(pv2p), 
            pv2p_winner=first(pv2p),
            poll_margin=first(avg_support)-last(avg_support))

# Correlation between November poll margin and two-party PV margin is:

cor(pollnov_vote_margin_df$pv2p_margin, pollnov_vote_margin_df$poll_margin) # 0.87

pollnov_vote_margin_df %>%
  ggplot(aes(x=poll_margin, y=pv2p_margin,
             label=year)) + 
    geom_text() +
    xlim(c(-5, 25)) + ylim(c(-5, 25)) +
    geom_abline(slope=1, lty=2) +
    geom_vline(xintercept=0, alpha=0.2) + 
    geom_hline(yintercept=0, alpha=0.2) +
    xlab("winner's polling margin in November") +
    ylab("winner's two-party voteshare margin") +
    theme_bw()

## What about the earliest polls at the start of the race?
# Does the January poll predict the election? Do we know the result by then?

polljan_vote_margin_df <- poll_df %>% 
  group_by(year, party) %>%
  top_n(-1, poll_date) %>% ## this is all that changes from the last codeblock
  left_join(popvote_df, by = c("year"="year", "party"="party")) %>%
  group_by(year) %>% arrange(-winner) %>% 
  summarise(pv2p_margin=first(pv2p)-last(pv2p), 
            pv2p_winner=first(pv2p),
            poll_margin=first(avg_support)-last(avg_support))

polljan_vote_margin_df %>%
  ggplot(aes(x=poll_margin, y=pv2p_margin, label=year)) + 
    geom_text() +
    xlim(c(-5, 40)) + ylim(c(-5, 40)) +
    geom_abline(slope=1, lty=2) +
    geom_vline(xintercept=0, alpha=0.2) + 
    geom_hline(yintercept=0, alpha=0.2) +
    xlab("winner's polling margin in January") +
    ylab("winner's two-party voteshare margin") +
    theme_bw()#
