# Final Prediction

11/1/2020

With only days until the 2020 Presidential election, I will be making my final election prediction. In this post I will make a prediction about the two-party vote share in each state, the national two-party vote share, and the electoral vote result. 


# Basis for the Prediction

In a previous blog post I considered the effectiveness of polling. I found that **state polling data tends to converge very well on the actual two party vote share** for the state (and national polling data shows much less of a convergence). For this reason, I am using only **state level October and November polling** to make the state level vote share prediction. This is consistent with major forecasting models which tend to have polling dominate their model once the election is very close. This strategy makes sense because long before the election there is a lot more uncertainty about how the polls may change before election day so it is necessary to use other, more rigid factors to make the prediction more stable and to better account for the uncertainty. Since the **polling uncertainty decreases very close to the election**, we do not need more variables to have strong predictive power.

In summary my model makes a prediction on the two-party vote share of each candidate in each state based on their polling average (as given on [538](https://projects.fivethirtyeight.com/polls/president-general/national/) on 10/30/2020)

As a consequence, the model I am using for this prediction is not the most useful model when trying to predict the election long before election day because, of course, October and November polling data will not be available yet. However, close to the election, this is a reasonable basis for a prediction.

To predict the national two-party vote share, I use the predicted state level two-party vote shares and **weight them by the size of their voting eligible populations (VEP)**. Although this method does not account for possible *differences in turnout* between states, historical data indicates that **state level two-party vote shares aggregate to a close estimate of the national two-party vote** share despite the possibility of different turnout rates.

To predict the final electoral vote share and map, I will again start with my predicted state-level two-party vote shares. I will generate **win odds for Trump in each state** by looking at historical data for how often a candidate wins with different polling numbers. I will estimate of Donald Trump's win odds for the overall 2020 presidential election by **simulating the election 10,000 times** with the state win probabilities found from the polling data.

# The Model

## State-Level Two-Party Vote Share

To predict the state level two-party vote share, I perform a **linear regression** on the relationship between **polling in the October and November** and the **actual two-party vote share** in that election.

![national vote share from state vote share](../figures/polling_vs_actual.png)

In the figure, the red line shows the line Vote Share = Polling Average and the blue line shows the regression line.

The regression line is given by the equation:

**Republican Vote Share = 1.03279*(Republican Polling Average) - 1.13674**

First we note that this line is fairly close to the line of *Vote Share = Polling Average*. This makes sense because both vote share and polling average are measures of which candidate people want to win. We can interpret the coefficients as corrections for the way in which polling tends to be wrong historically. In particular we observe that **if Republicans and Democrats are polling equivalently (50% for each party), then the Republican is predicted to get a higher two-party vote share**. This means that my model is adjusting for the fact that in close states, the polling tends to expect a higher Democratic vote share than tends to result. 

**Validation**
The adjusted rsquared value for the regression line is 0.925. This means that the **in-sample fit of the line is very strong**. Furthermore, by performing *leave-one-out cross validation* I found the model has an rsquared of 0.924 and a root mean squared error of 2.734. This means that the **out-of-sample fit for the line is also very strong**. In other words, **it is reasonable to use this as my model for predicting the state two-party popular vote shares**. However, it is worth noting that **predictions made with this model will carry uncertainty** that is quantified by the RMSE of 2.734.


### Making a Prediction
Now we can use this regression to predict the two-party vote in each state. In looking at the following table, recall that each prediction has an RMSE of 2.734. All vote shares are given as percentages.

![table of state vote share predictions](../figures/table_state_predictions.png)

Aggregating these predictions into a map, we get a **predicted electoral map** of:

![electoral map from state popular vote predictions](../figures/polling_state_predictions.png)

However, again it is worth recalling that 

## National Two-Party Vote Share

First, consider whether it is reasonable that we use our state-level two-party vote share to predict the national vote share. Below I compare the **national vote share given by weighting each state vote share by it's VEP** to the **actual national vote share** in that election.

![national vote share from state vote share](../figures/national_votes_from_states.png)

We see the relationship is very strong and that the regression line (in blue) effectively matches the line * y = x* indicating that **it is reasonable that we use our state-level two-party vote share to predict the national vote share**.

Now we can use our state level predictions to generate a prediction for the national two party vote share of the two candidates using [2020 VEP data](http://www.electproject.org/2020g). Using this weighting we predict the following result for national two party vote share:

| Candidate | National Two-Party Vote Share |
|-----------|-------------------------------|
| Trump     | 46.1                          |
| Biden     | 53.9                          |

It is difficult to quantify the uncertainty on this prediction because there is ***uncertainty*** both from the fact that I am using *predicted* two-party vote share instead of *actual* two-party vote share, and from the fact that **there may be different voter turnouts in each state**. Recall from above that each of the state popular vote predictions has a root mean squared error (RMSE) of 2.73; we can use this as a sort of proxy for error in this prediction. We observe that Trump's predicted two-party popular vote share is within two RMSE of giving him a majority of the vote. This means that **I predict Biden will win the national two-party vote**, ***but*** **there is a reasonable probability that Trump wins the national two-party popular vote**.

## Electoral Vote Prediction

![win probabilities](../figures/win_probabilities.png)

I simulated the election 10,000 times using the win probabilities determined by current polling averages and based on historical data on win rates for states with these polling averages.

![simulated electoral vote counts](../figures/simulated_electoral_vote.png)

From this plot we can see that Trump 

