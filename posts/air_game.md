## The Air Game

10/11/2020

In this post I explore the effect of advertising on the US Presidential Election

# Relevant Considerations

For the sake of this exploration I confine myself to money spent on advertising in the month of September. This is because this is advertising data closest to the election that I have access to. It has been argued that the effects of advertising are significant, but decay rapidly over time. Thus, restricting myself to only the advertising closest to the election (for which I have data) should be a fairly reasonable choice.

In a given election, not every state can reasonably be considered to be competitive. We might expect that spending in states that are not competitive will not have a significant impact on the result in those states. For this reason, I separately consider the effects of advertising on safe democrat states, safe republican states, and battleground states. I create these categories by taking all states deemed "swing" states in the federal funding data set to be battleground states, and any state decided by less than a 5 point two-party popular vote margin to be a battleground state. For non-battleground states, I categorize "safe democrat" and "safe republican" by retroactively observing the winner and taking that result to have been "safe".

Based on constraints on available data about money spent on advertising, I only consider historical data from the election from 2000 to 2012. This is unfortunately a small data set and therefore limits the predictive power of my analysis.

# Historical Trends in Spending 



![image of average absolute spending](../figures/absolute_spending.png)

## Analysis of Plots



![image of average proportional spending](../figures/normalized_spending.png)

## Analysis of Plot


# Using Historical Data to Predict 2020



![image of trend in popular vote by spending difference](../figures/republican_spending_advantage.png)

For the safe states, we see that the data varies drastically in terms of two party vote share for similar differences in advertising spending. This tells us that it is not useful to 

We observe that when Republicans and Democrats match each others' spending in a battleground state, the Republican tends to do slightly better. This seems to counterbalance the fact that Democrats tend to outspend Republicans in the elections since 2000.

# Prediction

For 2020, I have data on the number of airings by each candidate in each state in September and I have the total spending on advertising by the two candidates in that time period. I assume that  

![2020 electoral prediction from september spending](../figures/prediction_by_spending.png)



# Conclusion

  Trump: 208 Electoral Votes
  Biden: 330: Electoral Votes