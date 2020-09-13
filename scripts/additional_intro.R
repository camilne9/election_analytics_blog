library(tidyverse)
library(ggplot2)
library(usmap)
library(ggthemes)

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

swing_closer_08_12 <- pvstate_df %>%
  filter(year %in% c(2008, 2012)) %>%
  select(state, year, D_pv2p, R_pv2p) %>%
  mutate(margin = D_pv2p-R_pv2p) %>%
  select(state, year, margin) %>% 
  pivot_wider(names_from = year, values_from = margin) %>% 
  rename(year_2008 = "2008") %>% 
  rename(year_2012 = "2012") %>% 
  mutate(closer = (abs(year_2008) > abs(year_2012))) %>% 
  group_by(closer) %>% 
  summarise(smaller_margin = n()) %>% 
  ungroup() %>% 
  mutate(proportion_closer = smaller_margin/sum(smaller_margin)) %>% 
  mutate(closer = str_replace(closer, "TRUE", "Closer")) %>% 
  mutate(closer = str_replace(closer, "FALSE", "Less Close"))

mycolors <- c("#F0FC62", "#D0A2F5")

ggplot(swing_closer_08_12, aes(x ="", y=proportion_closer, fill = closer))+
  geom_bar(width = 1, stat = "identity")+
  coord_polar("y", start=0)+
  ylab("")+
  xlab("")+
  labs(title = "Proportion of States with Closer Popular Votes in 2012 than 2008")+
  theme_minimal()+
  theme(legend.title = element_blank())+
  scale_fill_manual(values = mycolors)

ggsave("../figures/closer_08_12.png", height = 5, width = 7)


swing_closer_00_04 <- pvstate_df %>%
  filter(year %in% c(2000, 2004)) %>%
  select(state, year, D_pv2p, R_pv2p) %>%
  mutate(margin = D_pv2p-R_pv2p) %>%
  select(state, year, margin) %>% 
  pivot_wider(names_from = year, values_from = margin) %>% 
  rename(year_2000 = "2000") %>% 
  rename(year_2004 = "2004") %>% 
  mutate(closer = (abs(year_2000) > abs(year_2004))) %>% 
  group_by(closer) %>% 
  summarise(smaller_margin = n()) %>% 
  ungroup() %>% 
  mutate(proportion_closer = smaller_margin/sum(smaller_margin)) %>% 
  mutate(closer = str_replace(closer, "TRUE", "Closer")) %>% 
  mutate(closer = str_replace(closer, "FALSE", "Less Close"))

ggplot(swing_closer_00_04, aes(x ="", y=proportion_closer, fill = closer))+
  geom_bar(width = 1, stat = "identity")+
  coord_polar("y", start=0)+
  ylab("")+
  xlab("")+
  labs(title = "Proportion of States with Closer Popular Votes in 2004 than 2000")+
  theme_minimal()+
  theme(legend.title = element_blank())+
  scale_fill_manual(values = mycolors)

ggsave("../figures/closer_00_04.png", height = 5, width = 7)

