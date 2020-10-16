#### Ground Game ####
#### Gov 1347: Election Analysis (2020)
#### TFs: Soubhik Barari, Sun Young Park

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

## install via `install.packages("name")`
library(tidyverse)
library(knitr)
library(stargazer)
library(usmap)
library(rgdal)
library(cowplot)
library(statebins)

## set working directory here
setwd("~")

####----------------------------------------------------------#
#### Where should campaigns build field offices? ####
####----------------------------------------------------------#

fo_2012 <- read_csv("fieldoffice_2012_bycounty.csv")

lm_obama <- lm(obama12fo ~ romney12fo +
                 swing + core_rep +
                 swing:romney12fo + core_rep:romney12fo + battle +
                 medage08 + pop2008 + pop2008^2 + medinc08 +
                 black + hispanic + pc_less_hs00 + pc_degree00 + 
                 as.factor(state), fo_2012)
lm_romney <- lm(romney12fo ~ obama12fo +
                  swing + core_dem +
                  swing:obama12fo + core_dem:obama12fo + battle +
                  medage08 + pop2008 + pop2008^2 + medinc08 +
                  black + hispanic + pc_less_hs00 + pc_degree00 + 
                  as.factor(state), fo_2012)

stargazer(lm_obama, lm_romney, header=FALSE, type='latex', no.space = TRUE,
          column.sep.width = "3pt", font.size = "scriptsize", single.row = TRUE,
          keep = c(1:7, 62:66), omit.table.layout = "sn",
          title = "Placement of field offices (2012)")

####----------------------------------------------------------#
#### Effects of field offices on turnout and vote share
####----------------------------------------------------------#

fo_dem <- read_csv("fieldoffice_2004-2012_dems.csv")

ef_t <- lm(turnout_change ~ dummy_fo_change +
             battle + dummy_fo_change:battle +
             as.factor(state) + as.factor(year), fo_dem)

ef_d <- lm(dempct_change ~ dummy_fo_change +
             battle + dummy_fo_change:battle + 
             as.factor(state) + as.factor(year), fo_dem)

stargazer(ef_t, ef_d, header=FALSE, type='latex', no.space = TRUE,
          column.sep.width = "3pt", font.size = "scriptsize", single.row = TRUE,
          keep = c(1:3, 53:54), keep.stat = c("n", "adj.rsq", "res.dev"),
          title = "Effect of Dem field offices on turnout and Dem vote-share (2004-2012)")

####----------------------------------------------------------#
#### Field strategies of Clinton and Trump in 2016
####----------------------------------------------------------#

fo_add <- read_csv("fieldoffice_2012-2016_byaddress.csv")

obama12 <- subset(fo_add, year == 2012 & candidate == "Obama") %>%
  select(longitude, latitude)
romney12 <- subset(fo_add, year == 2012 & candidate == "Romney") %>%
  select(longitude, latitude)
clinton16 <- subset(fo_add, year == 2016 & candidate == "Clinton") %>%
  select(longitude, latitude)
trump16 <- subset(fo_add, year == 2016 & candidate == "Trump") %>%
  select(longitude, latitude)

states_map <- usmap::us_map()
obama12_transformed <- usmap_transform(obama12)
romney12_transformed <- usmap_transform(romney12)
clinton16_transformed <- usmap_transform(clinton16)
trump16_transformed <- usmap_transform(trump16)

ob12 <- plot_usmap(regions = "states", labels = TRUE)+
  geom_point(data = obama12_transformed, aes(x = longitude.1, y = latitude.1), color = "blue", alpha = 0.75, pch=3)+
  ggtitle("Obama 2012")+
  theme(plot.title = element_text(size=18, face="bold"))

ro12 <- plot_usmap(regions = "states", labels = TRUE)+
  geom_point(data = romney12_transformed, aes(x = longitude.1, y = latitude.1), color = "red", alpha = 0.75, pch=3)+
  ggtitle("Romney 2012")+
  theme(plot.title = element_text(size=18, face="bold"))

cl16 <- plot_usmap(regions = "states", labels = TRUE)+
  geom_point(data = clinton16_transformed, aes(x = longitude.1, y = latitude.1), color = "blue", alpha = 0.75, pch=3)+
  ggtitle("Clinton 2016")+
  theme(plot.title = element_text(size=18, face="bold"))

tr16 <- plot_usmap(regions = "states", labels = TRUE)+
  geom_point(data = trump16_transformed, aes(x = longitude.1, y = latitude.1), color = "red", alpha = 0.75, pch=3)+
  ggtitle("Trump 2016")+
  theme(plot.title = element_text(size=18, face="bold"))

plot_grid(ob12, ro12, cl16, tr16)

# Clinton '16 field offices - Obama '08 field offices

fo_add %>%
  subset(candidate %in% c("Clinton", "Obama") &
           state %in% c("CO", "FL", "IA", "MI", "NV", "NH", "NC", "OH", "PA", "VA", "WI")) %>%
  group_by(state, candidate) %>%
  summarize(fo = n()) %>%
  spread(key = candidate, value = fo) %>%
  mutate(diff = Clinton - Obama) %>%
  select(state, diff) %>%
  ggplot(aes(y = diff, x = state, fill = (diff > 0))) +
  geom_bar(stat = "identity") +
  coord_flip() +
  ylim(-50, 15) +
  scale_y_continuous(breaks=seq(-50,10,10)) +
  xlab("state") +
  ylab("Clinton '16 field offices - Obama '08 field offices")+
  theme_minimal() +
  theme(legend.position = "none",
        text = element_text(size = 15))

# Wisconsin: field office

obama12_wi <- subset(fo_add, year == 2012 & candidate == "Obama" & state == "WI") %>%
  select(longitude, latitude)
clinton16_wi <- subset(fo_add, year == 2016 & candidate == "Clinton" & state == "WI") %>%
  select(longitude, latitude)

obama12wi_transformed <- usmap_transform(obama12_wi)
clinton16wi_transformed <- usmap_transform(clinton16_wi)

ob_wis <- plot_usmap(regions = "counties", include = c("WI"))+
  geom_point(data = obama12wi_transformed, aes(x = longitude.1, y = latitude.1), color = "blue", alpha = 0.75, pch=3, size=3, stroke=1)+
  ggtitle("Obama 2012 (Wisconsin)")+
  theme(plot.title = element_text(size=14, face="bold"))

cl_wis <- plot_usmap(regions = "counties", include = c("WI"))+
  geom_point(data = clinton16wi_transformed, aes(x = longitude.1, y = latitude.1), color = "blue", alpha = 0.75, pch=3, size=3, stroke=1)+
  ggtitle("Clinton 2016 (Wisconsin)")+
  theme(plot.title = element_text(size=14, face="bold"))

plot_grid(ob_wis, cl_wis)

# Wisconsin: pv

pvcounty_wi <- read_csv("popvote_bycounty_2012-2016_WI.csv")

obama12_wi <- subset(fo_add, year == 2012 & candidate == "Obama" & state == "WI") %>%
  select(longitude, latitude)
pv12_wi <- subset(pvcounty_wi, year == 2012)

clinton16_wi <- subset(fo_add, year == 2016 & candidate == "Clinton" & state == "WI") %>%
  select(longitude, latitude)
pv16_wi <- subset(pvcounty_wi, year == 2016)

obama12wi_transformed <- usmap_transform(obama12_wi)
clinton16wi_transformed <- usmap_transform(clinton16_wi)

ob_wis <- plot_usmap(regions = "counties", data = pv12_wi, values = "D_win_margin", include = c("WI"))+
  geom_point(data = obama12wi_transformed, aes(x = longitude.1, y = latitude.1), color = "blue", alpha = 0.75, pch=3, size=3, stroke=1)+
  scale_fill_gradient2(
    high = "blue", mid = "white", low = "red",
    name = "Dem\nwin margin"
  ) + 
  ggtitle("Obama 2012 (Wisconsin)")+
  theme(plot.title = element_text(size=16, face="bold")) + theme(legend.position = "right")

cl_wis <- plot_usmap(regions = "counties", data = pv16_wi, values = "D_win_margin", include = c("WI"))+
  geom_point(data = clinton16wi_transformed, aes(x = longitude.1, y = latitude.1), color = "blue", alpha = 0.75, pch=3, size=3, stroke=1)+
  ggtitle("Clinton 2016 (Wisconsin)")+
  scale_fill_gradient2(
    high = "blue", mid = "white", low = "red",
    name = "Dem\nwin margin"
  ) +
  theme(plot.title = element_text(size=16, face="bold")) + theme(legend.position = "right")

plot_grid(ob_wis, cl_wis)
