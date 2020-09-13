library(tidyverse)
library(ggplot2)
library(usmap)

setwd("~/gov1347/election_analytics_blog/scripts")

popvote_df <- read_csv("../data/popvote_1948-2016.csv")
pvstate_df <- read_csv("../data/popvote_bystate_1948-2016.csv")


pv_swing_08_12 <- pvstate_df %>%
  filter(year %in% c(2008, 2012)) %>%
  select(state, year, D_pv2p, R_pv2p) %>% 
  pivot_wider(names_from = year, values_from = c(D_pv2p, R_pv2p)) %>% 
  mutate(swing_blue = D_pv2p_2012-D_pv2p_2008) %>% 
  mutate(swing_red = R_pv2p_2012-R_pv2p_2008) %>% 
  select(state, swing_blue, swing_red)

plot_usmap(data = pv_swing_08_12, regions = "states", values = "swing_red") +
  scale_fill_gradient2(
    high = "red", 
    mid = "white",
    low = "blue", 
    breaks = c(-10,-5,0,5,10), 
    limits = c(-10.5,10.5),
    name = "Republican Swing"
  ) +
  theme_void()+
  labs(title = "Change in Two Party Vote Share 2008 to 2012")

ggsave("../figures/swing_08_12.png", height = 4, width = 8)
  

pv_swing_00_04 <- pvstate_df %>%
  filter(year %in% c(2000, 2004)) %>%
  select(state, year, D_pv2p, R_pv2p) %>% 
  pivot_wider(names_from = year, values_from = c(D_pv2p, R_pv2p)) %>% 
  mutate(swing_blue = D_pv2p_2004-D_pv2p_2000) %>% 
  mutate(swing_red = R_pv2p_2004-R_pv2p_2000) %>% 
  select(state, swing_blue, swing_red)

plot_usmap(data = pv_swing_00_04, regions = "states", values = "swing_red") +
  scale_fill_gradient2(
    high = "red", 
    mid = "white",
    low = "blue", 
    breaks = c(-10,-5,0,5,10), 
    limits = c(-10.5,10.5),
    name = "Swing"
  ) +
  theme_void()+
  labs(title = "Change in Two Party Vote Share 2000 to 2004")

ggsave("../figures/swing_00_04.png", height = 4, width = 8)


