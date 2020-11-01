# Final Prediction

11/1/2020

With only days until the 2020 Presidential election, I will be making my final election prediction. In this post I will make a prediction about the two-party vote share in each state, the national two-party vote share, and the 


# Basis for the Prediction

In a previous blog post I considered the effectiveness of polling. I found that state polling data tends to converge very well on the actual two party vote share for the state (and national polling data shows much less of a convergence). For this reason, I am using only state level October and November polling to make the state level vote share prediction. This is consistent with major forecasting models which tend to have polling dominate their model once the election is very close. This strategy makes sense because long before the election there is a lot more uncertainty about how the polls may change before election day so it is necessary to use other, more rigid factors to make the prediction more stable and better account for the uncertainty. Since that polling uncertainty decreases very close to the election, we do not need more variables to have strong predictive power.

As a consequence, the model I am using for this prediction is not the most useful model when trying to predict the election long before election day because, of course, October and November polling data may not be available yet. However, close to the election, this is a reasonable basis for a prediction.

To predict the national two-party vote share, I use the predicted state level two-party vote shares and weight them by the size of their voting eligible populations. Although this method does not account for possible difference in turnout between states, historical data indicates that state level two-party vote shares aggregate to a close estimate of the national two-party vote share despite the possibility of different turnout rates.

To predict the final electoral vote share and map, I will again start with py predicted state-level two-party vote shares. I will generate win odds for Trump in each state by looking at historical data for how often 
I will also use electoral vote share to make an estimate of Donald Trump's win odds by simulating that election 10,000 times

# The Model

## State-Level Two-Party Vote Share

To predict the state level two-party vote share, I perform a linear regression on the relationship between polling in the October and November and the actual two-party vote share in that election.

![national vote share from state vote share](../figures/polling_vs_actual.png)

The regression line is given by the equation:

Republican Vote Share = 1.03*(Republican Polling Average) - 1.3

First we note that this line is fairly close to the line of Vote Share = Polling Average. This makes sense because both vote share and polling average are measures of which candidate people want to win. We can interpret the coefficients as the ways in which polling tends to be wrong historically. In particular we observe that if Republicans and Democrats are polling equivalently (50% for each party), then the Republican is predicted to get a higher two-party vote share. This means that my model is adjusting for the fact that in close states, the polling tends to expect a higher Democratic vote share than tends to result. 


### Making a Prediction
Now we can use this regression to predict states 

![table of state vote share predictions](../figures/table_state_predictions.png)

Aggregating these predictions into a map, we get a predicted electoral map of:

![electoral map from state popular vote predictions](../figures/polling_state_predictions.png)


## National Two-Party Vote Share

First, consider whether it is reasonable that we use our state-level two-party vote share to predict the 

![national vote share from state vote share](../figures/national_votes_from_states.png)

Now we can use our state level predictions to generate a prediction for the national two party vote share of the two candidates using [2020 VEP data](http://www.electproject.org/2020g). Using this weighting we predict the following result for national two party vote share:

| Candidate | National Two-Party Vote Share |
|-----------|-------------------------------|
| Trump     | 46.1                          |
| Biden     | 53.9                          |

It is difficult to quantify the uncertainty on this prediction because there is ***uncertainty*** both from the fact that I am using *predicted* two-party vote share instead of *actual* two-party vote share, and from the fact that **there may be different voter turnouts in each state**. Recall from above that each of the state popular vote predictions has a root mean squared error (RMSE) of 2.73; we can use this as a sort of proxy for error in this prediction. We observe that Trump's predicted two-party popular vote share is within two RMSE of giving him a majority of the vote. This means that despite the fact that **I predict Biden will win the national two-party vote**, **there is a reasonable probability that Trump wins the national two-party popular vote**.

## Electoral Vote Prediction

![win probabilities](../figures/win_probabilities.png)

I simulated the election 10,000 times using the win probabilities determined by current polling averages and based on historical data on win rates for states with these polling averages.

![simulated electoral vote counts](../figures/simulated_electoral_vote.png)

From this plot we can see that Trump 

