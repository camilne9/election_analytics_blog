#### Campaigns ####
#### Gov 1347: Election Analysis (2020)
#### TFs: Soubhik Barari, Sun Young Park

####----------------------------------------------------------#
#### Pre-amble ####
####----------------------------------------------------------#

## install via `install.packages("name")`
library(quanteda) ## package for analyzing text-as-data
library(tidyverse)
library(ggplot2)

## set working directory here
setwd("~/gov1347/election_analytics_blog/scripts")

#####------------------------------------------------------#
##### Example 1: summarise inaugural addresses ####
#####------------------------------------------------------#

# Presidential inaugural addresses 1789-2017 
# (pre-formatted as `quanteda` corpus)
View(data_corpus_inaugural)

## pre-process: tokenize, lowercase, and remove stopwords
toks_inaugural <- tokens(data_corpus_inaugural, remove_punct = TRUE) %>% 
    tokens_tolower() %>%
    tokens_remove(pattern = stopwords("en"))

## pre-process: make document-frequency matrix (words)
dfm_inaugural <- dfm(toks_inaugural)

## summarise: word frequencies 
tstat_freq <- textstat_frequency(dfm_inaugural)
head(tstat_freq, 10)

## visualise: word frequencies
textplot_wordcloud(dfm_inaugural)

#####------------------------------------------------------#
##### Example 2: summarise inaugural addresses ####
#####------------------------------------------------------#

## pre-process: make document-frequency matrix (words)
##              grouped by president
dfm_inaugural <- dfm(toks_inaugural, groups = "President")

## pre-process: tokenize, lowercase, remove stopwords, select >5 letter words
toks_inaugural <- tokens(data_corpus_inaugural, remove_punct = TRUE) %>% 
    tokens_tolower() %>%
    tokens_remove(pattern = stopwords("en")) %>%
    tokens_remove(pattern = "president") %>%
    tokens_select(min_nchar=6)

## pre-process: make document-frequency matrix (words)
dfm_inaugural <- dfm(toks_inaugural, groups = "President")

## visualise: word frequencies
textplot_wordcloud(dfm_inaugural)

## summarise: word frequencies 
tstat_freq <- textstat_frequency(dfm_inaugural)
head(tstat_freq, 10)

## visualise: word frequencies
textplot_wordcloud(dfm_inaugural)

## visualise: word "keyness" for a specific group of documents
trump_keyness <- textstat_keyness(dfm_inaugural, target = "Trump")
textplot_keyness(trump_keyness)

#####------------------------------------------------------#
##### Application: Trump vs. Biden campaign speeches ####
#####------------------------------------------------------#

speech_df <- read_csv("campaignspeech_2019-2020.csv")

## pre-process: make a `quanteda` corpus from dataframe
speech_corpus <- corpus(speech_df, text_field = "text", docid_field = "url")

## pre-process: tokenize, clean, select n-grams
speech_toks <- tokens(speech_corpus, 
    remove_punct = TRUE,
    remove_symbols = TRUE,
    remove_numbers = TRUE,
    remove_url = TRUE) %>% 
    tokens_tolower() %>%
    tokens_remove(pattern=c("joe","biden","donald","trump","president","kamala","harris")) %>%
    tokens_remove(pattern=stopwords("en")) %>%
    tokens_select(min_nchar=3) %>%
    tokens_ngrams(n=2)

## pre-process: make doc-freq matrix
speech_dfm <- dfm(speech_toks, groups = "candidate")

## summarise and visualise
tstat_freq <- textstat_frequency(speech_dfm)
head(tstat_freq, 100)

textplot_wordcloud(my_dfm, color = c("red", "blue"), comparison = T)

trump_keyness <- textstat_keyness(my_dfm, target = "Donald Trump")
textplot_keyness(trump_keyness)

#####------------------------------------------------------#
##### Application: Trump tweets ####
#####------------------------------------------------------#

trump_tweets <- read_csv("../data/trumptweets_2016-2020.csv")


# Deleted tweets (no retweets)
trump_tweets2 <- trump_tweets %>% 
    filter(isRetweet == FALSE) 

trump_tweets2 %>% 
    filter(isDeleted)
    
tweet_corpus <- corpus(trump_tweets2, text_field = "text", docid_field = "id")

tweet_toks <- tokens(tweet_corpus, 
                      remove_punct = TRUE,
                      remove_symbols = TRUE,
                      remove_numbers = TRUE,
                      remove_url = TRUE) %>% 
    tokens_tolower() %>%
    tokens_remove(pattern=c("joe","biden","donald","trump","president","kamala","harris", str_detect("@"))) %>%
    tokens_remove(pattern=stopwords("en")) %>%
    tokens_select(min_nchar=3) %>%
    tokens_ngrams(n=2)

tweet_dfm <- dfm(tweet_toks, groups = "isDeleted")

tweet_stat_freq <- textstat_frequency(tweet_dfm)
head(tweet_stat_freq, 100)

textplot_wordcloud(tweet_dfm, color = c("red", "blue"), comparison = T)

deleted_tweet_keyness <- textstat_keyness(tweet_dfm, target = "FALSE")
textplot_keyness(deleted_tweet_keyness)

trump_tweets$text <- gsub("https.*","", trump_tweets$text)
trump_tweets$text <- gsub("@.*","", trump_tweets$text)
