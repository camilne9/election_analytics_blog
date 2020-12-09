library(tidyverse)
library(janitor)

setwd("~/gov1347/election_analytics_blog/scripts")

# I read in the data
results <- read_csv("../data/results2020_11-11.csv")
final_prediction <- read_csv("../data/final_prediction.csv")
all_results <- read_csv("../data/popvote_bystate_1948-2020.csv")
electors <- read_csv("../data/battleground.csv")
enos_results <- read_csv("../data/StateResults2020.csv") %>% 
  clean_names()
county_demog <- read_csv("../data/demog_county_1990-2018.csv")
county_results_2020 <- read_csv("../data/CountyResults2020.csv")
county_results_2016 <- read_csv("../data/popvote_bycounty_2000-2016.csv")
