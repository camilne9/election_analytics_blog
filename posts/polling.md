## Polling
9/27/2020

In this post I consider whether ***National*** **or** ***State*** **level polling** yields a more accurate prediction for the US presidential election. Based on the results of this investigation, I create a prediction for the 2020 presidential election used a weighted combination of state and national level polling.

# Gaps in the Data
Pollsters do not take polls in every state in every month of every election year. Thus, in order to compare how accurate polling data is by month, it is necessary to assign an expectation to month in which a poll is not taken. To this end, I made the following choices:

  * If a poll was not taken in a given month in a given state, but a poll was taken in that state in a previous month of the same election cycle, then I assume that the situation is the same as that most recent polling data
  * If there have been no polls in a given state for a particular election cycle, I assume the state will vote similarly to how it voted in the previous election.
  
Both of these choices were made with the idea that -in the absence of more recent data- using the **most recent data is the best available proxy**.

# Electoral Votes vs Popular Votes
When considering the 
To account in part for the impact of the electoral college in distorting the election results, I *normalize* the difference in electoral vote count as if the total number of electoral votes is 100. This makes the plots more reasonable to compare because two party popular vote share is constrained so that the total percentage of votes is 100%.

However, this normalization is not a perfect solution to comparing **electoral votes** and **two party popular vote share**. In general, the electoral college distorts the results of elections. Since each state is winner take all, *a small difference in votes in one state can be magnified into a large change in the electoral college* if it changes which party wins the state. This increased volatility of electoral college focused predictions means we expect a larger errors when considering electoral vote projections than when considering two party popular vote predictions.

One might ask why we bother to consider electoral predictions at all instead of also using the state polling to predict national two party vote share. While this would allow for easier comparison of the two types of polling data, since the **electoral college is ultimately what determines the presidency** (not the popular vote share), it is more important to know what this electoral college result will be. As such, I chose to consider the electoral vote counts at the expense of some cleanliness of comparison.

# Conclusion
We found that when the election is far away, national polling gives a better indication for who will win the election and when the election is close, th

# Model



# Prediction