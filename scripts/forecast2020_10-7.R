## Forecasting techniques / insights from the advertising week

library(tidyverse)
library(ggplot2)
library(geofacet) ## map-shaped grid of ggplots

#####------------------------------------------------------#
##### Read and merge data ####
#####------------------------------------------------------#

pvstate_df    <- read_csv("popvote_bystate_1948-2016.csv")
economy_df    <- read_csv("econ.csv")
pollstate_df  <- read_csv("pollavg_bystate_1968-2016.csv")

poll_pvstate_df <- pvstate_df %>%
  inner_join(
    pollstate_df %>% 
      filter(weeks_left == 5)
      # group_by(state, year) %>%
      # top_n(1, poll_date)
  )
poll_pvstate_df$D_pv <- (poll_pvstate_df$D / poll_pvstate_df$total)*100
poll_pvstate_df$R_pv <- (poll_pvstate_df$R / poll_pvstate_df$total)*100
poll_pvstate_df$state <- state.abb[match(poll_pvstate_df$state, state.name)]

#####------------------------------------------------------#
##### Map of univariate poll-based state forecasts ####
#####------------------------------------------------------#

state_forecast <- list()
state_forecast_outputs <- data.frame()
for (s in unique(poll_pvstate_df$state)) {
  state_forecast[[s]]$dat_D <- poll_pvstate_df %>% 
    filter(state == s, party == "democrat")
  state_forecast[[s]]$mod_D <- lm(D_pv ~ avg_poll, 
                                  state_forecast[[s]]$dat_D)
  
  state_forecast[[s]]$dat_R <- poll_pvstate_df %>% 
    filter(state == s, party == "republican")  
  state_forecast[[s]]$mod_R <- lm(R_pv ~ avg_poll, 
                                  state_forecast[[s]]$dat_R)
  if (nrow(state_forecast[[s]]$dat_R) > 2) {
    state_forecast_outputs <- rbind(
      state_forecast_outputs,
      rbind(
        cbind.data.frame(
          intercept = summary(state_forecast[[s]]$mod_D)$coefficients[1,1],
          intercept_se = summary(state_forecast[[s]]$mod_D)$coefficients[1,2],
          slope = summary(state_forecast[[s]]$mod_D)$coefficients[2,1],
          state = s, party = "democrat"),
        cbind.data.frame(
          intercept = summary(state_forecast[[s]]$mod_R)$coefficients[1,1],
          intercept_se = summary(state_forecast[[s]]$mod_R)$coefficients[1,2],
          slope = summary(state_forecast[[s]]$mod_R)$coefficients[2,1],
          state = s, party = "republican")
      )
    )
  }
}

## graphs: polls in different states / parties different levels 
##         of strength / significance of outcome
library(geofacet)
state_forecast_trends <- state_forecast_outputs %>% ##TODO: maybe place this above
  mutate(`0` = intercept,
         `25` = intercept + slope*25,
         `50` = intercept + slope*50,
         `75` = intercept + slope*75,
         `100` = intercept + slope*100) %>%
  select(-intercept, -slope) %>%
  gather(x, y, -party, -state, -intercept_se) %>%
  mutate(x = as.numeric(x))
  
## Q: what's wrong with this map?
## A: (1) no polls in some states 
##    (2) very high variance for some states / negative slopes 
##    (3) y not always in [0,100] range
ggplot(state_forecast_trends, aes(x=x, y=y, ymin=y-intercept_se, ymax=y+intercept_se)) + 
  facet_geo(~ state) +
  geom_line(aes(color = party)) + 
  geom_ribbon(aes(fill = party), alpha=0.5, color=NA) +
  coord_cartesian(ylim=c(0, 100)) +
  scale_color_manual(values = c("blue", "red")) +
  scale_fill_manual(values = c("blue", "red")) +
  xlab("hypothetical poll support") +
  ylab("predicted voteshare\n(pv = A + B * poll)") +
  ggtitle("") +
  theme_bw()

## North Dakota and Texas
state_forecast_trends %>%
  filter(state == "ND" | state == "TX") %>%
  ggplot(aes(x=x, y=y, ymin=y-intercept_se, ymax=y+intercept_se)) + 
  facet_wrap(~ state) +
  geom_line(aes(color = party)) + 
  geom_hline(yintercept = 100, lty = 3) +
  geom_hline(yintercept = 0, lty = 3) + 
  geom_ribbon(aes(fill = party), alpha=0.5, color=NA) +
  ## note: you can, in fact, combine *different* data and aesthetics
  ##       in one ggplot; but this usually needs to come at the end 
  ##       and you must explicitly override all previous aesthetics
  geom_text(data = poll_pvstate_df %>% filter(state == "ND", party=="democrat"), 
             aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  geom_text(data = poll_pvstate_df %>% filter(state == "ND", party=="republican"), 
             aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  geom_text(data = poll_pvstate_df %>% filter(state == "TX", party=="democrat"), 
             aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  geom_text(data = poll_pvstate_df %>% filter(state == "TX", party=="republican"), 
             aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  scale_color_manual(values = c("blue", "red")) +
  scale_fill_manual(values = c("blue", "red")) +
  xlab("hypothetical poll support") +
  ylab("predicted two-party voteshare\n(pv = A + B * poll)") +
  theme_bw()


#####------------------------------------------------------#
##### Map of PROBABILISTIC univariate poll-based state forecasts ####
#####------------------------------------------------------#

state_glm_forecast <- list()
state_glm_forecast_outputs <- data.frame()
poll_pvstate_vep_df$state_abb <- state.abb[match(poll_pvstate_vep_df$state, state.name)]
for (s in unique(poll_pvstate_vep_df$state_abb)) {
  
  state_glm_forecast[[s]]$dat_D <- poll_pvstate_vep_df %>% 
    filter(state_abb == s, party == "democrat")
  state_glm_forecast[[s]]$mod_D <- glm(cbind(D, VEP - D) ~ avg_poll, 
                                       state_glm_forecast[[s]]$dat_D,
                                       family = binomial(link="logit"))

  state_glm_forecast[[s]]$dat_R <- poll_pvstate_vep_df %>% 
    filter(state_abb == s, party == "republican")  
  state_glm_forecast[[s]]$mod_R <- glm(cbind(R, VEP - R) ~ avg_poll, 
                                       state_glm_forecast[[s]]$dat_R,
                                       family = binomial(link="logit"))
  
  if (nrow(state_glm_forecast[[s]]$dat_R) > 2) {
    for (hypo_avg_poll in seq(from=0, to=100, by=10)) {
      Dpred_voteprob <- predict(state_glm_forecast[[s]]$mod_D, 
                               newdata=data.frame(avg_poll=hypo_avg_poll), se=T, type="response")
      Dpred_q <- qt(0.975, df = df.residual(state_glm_forecast[[s]]$mod_D)) ## used in pred interval formula
        
      Rpred_voteprob <- predict(state_glm_forecast[[s]]$mod_R, 
                               newdata=data.frame(avg_poll=hypo_avg_poll), se=T, type="response")
      Rpred_q <- qt(0.975, df = df.residual(state_glm_forecast[[s]]$mod_R)) ## used in pred interval formula

      state_glm_forecast_outputs <- rbind(
        state_glm_forecast_outputs,
        cbind.data.frame(state = s, party = "democrat", x = hypo_avg_poll, 
                         y = Dpred_voteprob$fit*100, 
                         ymin = (Dpred_voteprob$fit - Rpred_q*Dpred_voteprob$se.fit)*100,
                         ymax = (Dpred_voteprob$fit + Rpred_q*Dpred_voteprob$se.fit)*100),
        cbind.data.frame(state = s, party = "republican", x = hypo_avg_poll, 
                         y = Rpred_voteprob$fit*100, 
                         ymin = (Rpred_voteprob$fit - Rpred_q*Rpred_voteprob$se.fit)*100,
                         ymax = (Rpred_voteprob$fit + Rpred_q*Rpred_voteprob$se.fit)*100)
      )
    }
  }
}

## graphs: polls in different states / parties different levels 
##         of strength / significance of outcome
ggplot(state_glm_forecast_outputs, aes(x=x, y=y, ymin=ymin, ymax=ymax)) + 
  facet_geo(~ state) +
  geom_line(aes(color = party)) + 
  geom_ribbon(aes(fill = party), alpha=0.5, color=NA) +
  coord_cartesian(ylim=c(0, 100)) +
  scale_color_manual(values = c("blue", "red")) +
  scale_fill_manual(values = c("blue", "red")) +
  xlab("hypothetical poll support") +
  ylab('probability of state-eligible voter voting for party') +
  theme_bw()

## North Dakota and Texas
state_glm_forecast_outputs %>%
  filter(state == "ND" | state == "TX") %>%
  ggplot(aes(x=x, y=y, ymin=ymin, ymax=ymax)) + 
  facet_wrap(~ state) +
  geom_line(aes(color = party)) + 
  geom_ribbon(aes(fill = party), alpha=0.5, color=NA) +
  coord_cartesian(ylim=c(0, 100)) +
  geom_text(data = poll_pvstate_df %>% filter(state == "ND", party=="democrat"), 
             aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  geom_text(data = poll_pvstate_df %>% filter(state == "ND", party=="republican"), 
             aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  geom_text(data = poll_pvstate_df %>% filter(state == "TX", party=="democrat"), 
             aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  geom_text(data = poll_pvstate_df %>% filter(state == "TX", party=="republican"), 
             aes(x = avg_poll, y = D_pv, ymin = D_pv, ymax = D_pv, color = party, label = year), size=1.5) +
  scale_color_manual(values = c("blue", "red")) +
  scale_fill_manual(values = c("blue", "red")) +
  xlab("hypothetical poll support") +
  ylab('probability of\nstate-eligible voter\nvoting for party') +
  ggtitle("Binomial logit") + 
  theme_bw() + theme(axis.title.y = element_text(size=6.5))

#####------------------------------------------------------#
##### Simulating a distribution of election results (PA) ####
#####------------------------------------------------------#

## Get relevant data
VEP_PA_2020 <- as.integer(vep_df$VEP[vep_df$state == "Pennsylvania" & vep_df$year == 2016])

PA_R <- poll_pvstate_vep_df %>% filter(state=="Pennsylvania", party=="republican")
PA_D <- poll_pvstate_vep_df %>% filter(state=="Pennsylvania", party=="democrat")

## Fit D and R models
PA_R_glm <- glm(cbind(R, VEP-R) ~ avg_poll, PA_R, family = binomial)
PA_D_glm <- glm(cbind(D, VEP-D) ~ avg_poll, PA_D, family = binomial)

## Get predicted draw probabilities for D and R
prob_Rvote_PA_2020 <- predict(PA_R_glm, newdata = data.frame(avg_poll=44.5), type="response")[[1]]
prob_Dvote_PA_2020 <- predict(PA_D_glm, newdata = data.frame(avg_poll=50), type="response")[[1]]

## Get predicted distribution of draws from the population
sim_Rvotes_PA_2020 <- rbinom(n = 10000, size = VEP_PA_2020, prob = prob_Rvote_PA_2020)
sim_Dvotes_PA_2020 <- rbinom(n = 10000, size = VEP_PA_2020, prob = prob_Dvote_PA_2020)

## Simulating a distribution of election results: Biden PA PV
hist(sim_Dvotes_PA_2020, xlab="predicted turnout draws for Biden\nfrom 10,000 binomial process simulations", breaks=100)

## Simulating a distribution of election results: Trump PA PV
hist(sim_Rvotes_PA_2020, xlab="predicted turnout draws for Trump\nfrom 10,000 binomial process simulations", breaks=100)

## Simulating a distribution of election results: Biden win margin
sim_elxns_PA_2020 <- ((sim_Dvotes_PA_2020-sim_Rvotes_PA_2020)/(sim_Dvotes_PA_2020+sim_Rvotes_PA_2020))*100
hist(sim_elxns_PA_2020, xlab="predicted draws of Biden win margin (% pts)\nfrom 10,000 binomial process simulations", xlim=c(2, 7.5))

#####------------------------------------------------------#
##### Advertising effects: A hypothetical air war in PA ####
#####------------------------------------------------------#

## how much 1000 GRP buys in % votes + how much it costs
GRP1000.buy_fx.huber     <- 7.5
GRP1000.buy_fx.huber_se  <- 2.5
GRP1000.buy_fx.gerber    <- 5
GRP1000.buy_fx.gerber_se <- 1.5
GRP1000.price            <- 300

## Suppose current (at-the-time) 538 polls were the *literal* individual
## probabilities that each voter turns out to vote blue/red
sim_Dvotes_PA_2020 <- rbinom(n = 10000, size = VEP_PA_2020, prob = 0.49)
sim_Rvotes_PA_2020 <- rbinom(n = 10000, size = VEP_PA_2020, prob = 0.42)
sim_elxns_PA_2020 <- (sim_Dvotes_PA_2020-sim_Rvotes_PA_2020)/(sim_Dvotes_PA_2020+sim_Rvotes_PA_2020)*100
hist(sim_elxns_PA_2020, xlab="", main="predicted Biden win margin (%) distribution", ylab="", cex.lab=0.5, 
     cex.axis=0.5, cex=0.5, cex.main=0.4, xaxs="i", yaxs="i", yaxt="n", bty="n", breaks=100)


## How much $ for Trump to get ~2% win margin?
## --> Trump needs to gain 10% 
((10/GRP1000.buy_fx.huber) * GRP1000.price * 1000)  ## price according to Huber et al
((10/GRP1000.buy_fx.gerber) * GRP1000.price * 1000) ## price according to Gerber et al

sim_elxns_PA_2020_shift.b <- sim_elxns_PA_2020 - rnorm(10000, 10, GRP1000.buy_fx.huber_se) ## shift from that buy according to Huber et al
sim_elxns_PA_2020_shift.a <- sim_elxns_PA_2020 - rnorm(10000, 10, GRP1000.buy_fx.gerber_se) ## shift from that buy according to Huber et al

## How much $ for Trump to get ~12% win margin?
## --> Trump needs to gain 20%
## --> double the estimates from above
par(mfrow=c(1,2))
{
hist(sim_elxns_PA_2020_shift.a, xlab="", 
     main="predicted Biden win margin (%) distribution\n - Gerber et al's estimated effect of 2000 Trump GRPs", 
     ylab="", cex.lab=0.5, cex.axis=0.5, cex=0.5, cex.main=0.4, xaxs="i", yaxs="i", yaxt="n", bty="n", 
     breaks=100, xlim=c(-10, 5))
hist(sim_elxns_PA_2020_shift.b, xlab="", 
     main="predicted Biden win margin (%) distribution\n - Huber et al's estimated effect of 1333 Trump GRPs", 
     ylab="", cex.lab=0.5, cex.axis=0.5, cex=0.5, cex.main=0.4, xaxs="i", yaxs="i", yaxt="n", bty="n", 
     breaks=100, xlim=c(-10, 5))
}

### NOTE:
### if GRPs have diminishing returns, then this is only true 
### if Trump didn't spend more than 6500 GRPs (according to Huber et al.)

