## Reflection

11/23/2020

With the results of the 2020 elections behind us (up to possible court case revisions), we can consider the 

Percentages taken from NYT on 11/11/2020

# Review of Model

My final election prediction was 


# The Error

My model consistently underestimated Trump's performance. The source of this error, naturally, is the polling error. 

The two party vote shares predicted by my model were within one RMSE of the actual values in most states, which suggests that the error was within a reasonable margin of error of my point estimate. However the fact that the error in my predictions was consistently in the same direction (underestimating Trump) suggest a systematic, methodological error that causes this discrepancy.


# Plan for Future Improvements

My model ultimately 
In a sense, this means I put all of my eggs in the same basket. The accuracy of my model was tied incredibly tightly to 

However, I still believe that the principle of weighting the polls heavily (even if less than in my model) is not necessarily a poor decision, given that the polls offer a direct lens in which to capture public opinion. This prompts me to consider how I can still lean on the polls without doing too much to tie my fate to the fate of the polls.
Keeping in mind a high level of dependence on the polls, it can become more important to consider how the polls have changed over time. In my model I found that on average the polls tend to underestimate the performance of the Republican party. However, this effect may be more (or less) pronounced as a function of recency or when conditioned on other variables (like incumbency).

Additionally, I should add considerations to the relatedness of different states. The results of different states are correlated (ie "Blue Wall" states)

another time I would also explicitly predict the districts in Maine and Nebraska

