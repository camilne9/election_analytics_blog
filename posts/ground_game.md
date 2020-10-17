## The Ground Game

10/18/2020

The *Ground Game* of a campaign includes all of the targeted efforts to appeal to specific individuals. The most commonly considered "ground game" factor is the presence of field offices and volunteer campaign workers that go door to door talking to people. Ground game efforts can be assessed on two metrics: how well they **persuade** people to vote a certain way and how well they **motivate** people to vote. Studies have found that the **ground game is more effective at motivating people to vote than it is at persuading people to change their vote**.

# Voter Turnout
Considering that **the ground game can have a impact on voter turnout**, it is worth considering how voter turnout can influence the result of an election. For this exploration I will restrict myself to **battleground states**. For states were the election is not competitive, the turnout will not determined the result so it is not meaningful to consider safe states. Thus, I will look at the results and the turnouts in **battleground states in elections from 1980 to 2016**. I define battleground states as states determined by less than 8 percentage points in two party popular vote share. This definition was chosen so that states in which the election was not decided by large margins, one could imagine that a significant shift in the number of voters could change the result of the election.

Let's consider how the voting turnout affects how often Democrats in a battleground state.

![image of Democratic win rate by voter turnout](../figures/turnout_vs_winrate.png)

# Turnout by Demographic

![proportion of white voters vs democratic vote share since 1992](../figures/white_vote_1992.png)

If we remove the elections in 1992 and 1996, however, we find the trend:

![proportion of white voters vs democratic vote share since 2000](../figures/white_vote_2000.png)


# Prediction

Turnout data is not the most useful variable for making predictions about an election result because **in order to predict an election based on turnout, you first need to predict turnout**. This, naturally, entails its own set of difficulties.

For this reason, I am going to make my prediction as a follow up to [my previous blog post considering polling](polling.md). In this previous blog post I made an electoral prediction based on current **national polling data**, current **state level polling data**, and the amount of **time until the election**. Since it has been about a month since I used this model to make a prediction, I am going to update my prediction using the same model and the most recent relevant polling data.

Recall that my model was:

***Electoral Prediction = (10 - months until election)/10 * State Poll Prediction+ (months until election)/10 * National Poll Prediction***

I acquired recent polling data (as of 10/17/2020) from [FiveThirtyEight](https://projects.fivethirtyeight.com/polls/president-general/national/). The current state polling suggests that the electoral map will be:



However, the **national popular vote would suggest a closer result** since the current polls give: 



Using my model to put together these considerations I predict that the final electoral counts will be:



Therefore, **I predict that Biden will in the 2020 US Presidential Election.**

