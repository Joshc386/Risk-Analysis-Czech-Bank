# Project Aims
The aim of this is to investigate whether there are characteristics that define if an individual is likely to pay their loan back or default. Several metrics will be assessed that look at financial data, social data and personal data to try and form a non-discriminatory filter to identify individuals with a larger probability of not paying back their loan.

## Data
The original data comes from The Berka Dataset which can be found here: https://www.kaggle.com/datasets/marceloventura/the-berka-dataset?select=loan.csv

# Loading
This was done through using the script 'LoadingScript.sql' and this was constructed by looking at the schema present on the website 'https://webpages.charlotte.edu/mirsad/itcs6265/group1/index.html'. The script was written all by hand and data was actually loaded after this schema was created by using the import on each newly created raw table. Data types were assigned by using the prior mentioned source as well as logic if no data type was stated in the documents.

# Cleaning
This was performed using the 'CleaningScript.sql' and quite a lot of cleaning was actually required due to the fact that a lot of the text was in Czech so translating it into English was a large part of the cleaning process. This was dealt with using a reference/translation table which is the 'ref.k_symbol' table and a lot of CASE statements in the transaction table and the standing_order table.
Implementing constraints into most rows also was necessary but predominantly 'NOT NULL' was put in-place as well as a few checks for columns that contain categorical variables such as male or female or the status column in the loan table that has to be either A, B, C or D. In the client table as well there was a significant piece of cleaning required due to the fact that the gender was encoded in the birth date of each client. Men have a birth date of the form YYMMDD and females have the form YYMM+50DD so removing the +50 from the date and recording the rows with the +50 to note that they are female was difficult and required the left-pad and right-pad functions and then extracting a specific part of the newly padded strings to get the correct month number. Labelling the gender was much easier as it all depended on the padding and substring extraction.
References was very important also to establish relationships between the tables otherwise the schema would be non-relational. This also dictated the order in which tables were created.

# Preliminary Analysis
This was done in the 'Preliminary.sql' file and essentially was used to explore the data and produce some summary statistics and assess the structure fully. There are 8 tables which are related to one another and their relationships are displayed below.
<p align="center">
  <img src="berka_tables.png" width="32%" alt="Tables present in the dataset">
</p>

There are 682 loans in total with a total loaned out of CZK103261740 and there are 76 'bad' loans that total to CZK15580152, whereby a bad loan is deemed as one with a status of B or D. B means the loan was not paid back and D means the loan is on-track to not be paid which gives an overall default rate of 11.1%. In the data there are 4500 accounts linked to Berka bank but only 682 of them have taken out loans.
Looking at a yearly view we see that there are 6 years where loans were issued (1993-1998) but the first loan was issued in July 1993 so only half of this year is present and the last loan was issued in early December of 1998 so these 2 years' totals are not as representative as the others. The table below shows all of the summary statistics for the yearly view.
| Loan year | Loans | Bad loans | Default rate | Finished loans | Finished unpaid | Finished default rate | Still running | Running, in arrears | Amount lent (CZK) | Lent on bad loans (CZK) |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 1993 | 20 | 4 | 20.0% | 20 | 4 | 20.0% | 0 | 0 | 2,619,276 | 811,284 |
| 1994 | 101 | 14 | 13.9% | 85 | 12 | 14.1% | 16 | 2 | 13,379,904 | 2,898,972 |
| 1995 | 90 | 12 | 13.3% | 51 | 6 | 11.8% | 39 | 6 | 13,344,372 | 1,880,184 |
| 1996 | 117 | 16 | 13.7% | 35 | 6 | 17.1% | 82 | 10 | 18,317,676 | 2,628,600 |
| 1997 | 196 | 26 | 13.3% | 43 | 3 | 7.0% | 153 | 23 | 30,731,364 | 6,263,292 |
| 1998 | 158 | 4 | 2.5% | 0 | 0 | – | 158 | 4 | 24,869,148 | 1,097,820 |
| **Total** | **682** | **76** | **11.1%** | **234** | **31** | **13.2%** | **448** | **45** | **103,261,740** | **15,580,152** |

Have to be careful with the different categories of loans, eg unpaid and finished, on track to be paid, etc. as they all represent different types of loans. In the 'proper' analysis we will mainly be looking at bad loans as defined above due to the fact that from the perspective of a bank, a loan that has finished in arrears is as bad as a loan that was unpaid.
A note with regards to 1998, 154 of the 158 loans are rated as C which means they are 'OK so far' and as statuses of A and B are the only ones with a final result these C-rated loans in reality would be difficult to rate as they are primarily new loans. What could be done is picking a point in time and assessing the loans using the individual's stats and their loan duration but this is highly inaccurate and makes a lot of assumptions that do not need to be made. This would produce results but mostly meaningless as they hinge on baseless assumptions.

# Views
The purpose of this is to create the necessary tables in order to create the correct visuals in Power BI. The reason views are used is due to the fact that the raw tables are not ideal for visualising and telling the appropriate story about the data. A view allows us to see a different side of the raw data ad the views have been catered to visualise the most important data/metrics.

# Analysis

This will look at several different metrics individually as well as combined metrics to try to determine what allows for the best filtering of customers without overfitting.

## Correlation Matrix
Correlation matrix. This is to assess which features to investigate individually as if 2 features are strongly correlated then investigating
both of them is pointless. The correlation between variables with is_bad will be of interest also as this is the whole purpose of the 
analysis: to try and see what indicates why a loan may not be paid back and classified as bad before it defaults.
Looking at the matrix, account age and number of transactions are highly correlated as these are similar metrics: an older account is more
likely to have more transactions than a younger account but age is not purely indicative of the number of transactions. The usage of account
age is better here as it is easier to make an inforceable rule. Transaction count can easily be manipulated to achieve a larger number of
them in a short period of time. A combination of both for deciding about loans is optimal.
There are several balance related metrics but the minimum balance will be investigated as XXX
Income and monthly payments are a huge part of figuring out whether a loan will default or not but these are relative to one another.
Monthly payments may be considered large but if the individual's income is very large then the monthly payment is manageable for them.
So assessing the affordability of a loan based on information prior to their loan is crucial here but not in isolation.


## Affordability
Trade-off at different affordability ratios. Reject if affordability ratio > cutoff value
Affordability by itself is a poor metric to use. It is evident that it does not capture relationships across the data well enough to be 
used as a defining metric by itself. It can be used to catch lots of bad loans effectively but in the process it will also catch lots of good
loans. At 0.35 which is probably the best compromise value it catches 26.3% of bad loans and 9.6% of good loans but catching only a quarter 
of bad loans is poor. At lower values such as 0.15 it catches 60.5% of bad loans but then rejects 46.4% of good loans.

Note on bad_value_avoided: parts of the loan are repaid so this column is slightly overstated
Can see that affordability is indicative of default rate at affordabilities where the individual's loan payment is high relative to their monthly income
Affordability ratio represents the ratio of an individual's monthly income going into their payments.
Only at higher affordability ratios do default rates rise significantly

## Minimum Balance
The filter of months_history = 6 is largely significant here. This filters to only loans from accounts that 
have at least 6 months of history/transactions with the bank prior to taking out a loan. Just looking
at each minimum balance band and all loans within those bands the default rate for the lowest band is just over 32%.
Looking at the lowest band with the 6 months filter we see that the default rate goes up to 50.56%. The reason
this is needed is that many newer accounts have a lower minimum balance simply due to account age. If 
we remove the months_history filter the lowest minimum balance band has an average age of 309 days and
the upper 3 tiers have ages of ~427 days. Adding in the 6 month filter the average account age for the 
lowest band goes up to 462 days, showing that this filter eliminates a lot of the younger accounts and this
could show that these accounts are in the lower band simply because they are newer.

Trade-off at each threshold value. Rule: decline if the minimum balance < cutoff value

For status B here the unrepaid share is 0.232 and using the ratio calculated above (1.166) 
this gives a break-even interest rate of 0.232 x 1.166 ~27%
A note on C and D: the unrepaid share is high simply because these loans have not yet finished yet

-- The rule avoids CZK 5569596 of bad-loan principal and decines 4775232 of good-loan principal, creating 
-- a ratio of ~1.17. But, a decline good loan only costs the bank in interest it would have earned and an approved 
-- bad loan costs only the unrepaid share of its principal, the loss given default or LGD.
-- The dataset does not record the interest paid so a break-even view is used instead but the rule to keep in mind is
-- LGD x 1.17 > lifetime interest earned as a percentage of the principal.
-- Assuming bad loans lose ~50% of principal still means that the rule pays as long as good loans do not earn
-- more than ~58% of principal interest over their life, which is far above the typical consumer-loan returns.
-- The ratios can be viewed by running line 126.

Want to look at the test rows here. For finished loans, 41 were finished
with 2/3 flagged correctly as bad and 16/38 flagged incorrectly as bad that 
were actually good, but this is quite a small sample size at only 41 loans and only 3 bad
loans in total so it is insufficient evidence.
For the running test loans 80% of bad loans were correctly
flagged as bad and only 10.1% of good loans were incorrectly fagged as bad, showing
the cutoff to be quite good at surfacing potential bad loans.

This test at the chosen cutoff shows 54 loans to be rejected where 22 of them were bad and 32 of them were good.
Test period has 296 good, 'mature' loans therefore 32/296 = 10.8% of good loans wrongly flagged.
40.7% of loans flagged are bad loans and 2.2% of unflagged loans were bad. False positive (falsely flagging a good loan)
rate is 10.8% and false negative (flagging a bad loan as good) rate is 2.2%. CI at 95% is 25.3 - 51.7 pp and 
z=9.2 corresponds to p~10^-20 and represents the probability of seeing a gap of 38.5 percentage points between if there is 
no real difference and is strong evidence to suggest that this gap is not due to random noise.

The confidence interval represents the interval which the size of the gap would fall into 95% of the time. 
The width is quite wide either side at 13.2 percentage points but this is mostly due to smaller groups. The
effect is definitely present but the size is uncertain. NOTE: the unflagged group only has 6 bad loans which is fine
but it just clears the requirement of 5 for the normal approximation. this analysis shows the effect is real
but does not quantify the effect of it

## Months Overdrawn
-- Can see that this is a huge discriminant in finding out if a loan will be good or bad.
-- Every single loan given out to an account that had at least 1 month of being in overdraft was a bad loan
-- but this is unclear if that is due to small sample size as only 20 accounts had months of overdraft
-- before the loan was take out compared to 662 that did not, but the fact that 100% of loans with at least 1
-- month overdrawn lead to 'B' or 'D' ratings is significant. It catches 26.3% of all bad loans

-- Very clear to see that even with the train/test split we see that 
-- if an account had any months where they were overdrawn prior to taking their
-- loan out the loan is bad 100% of the time with 9 bad loans in the train split
-- and 11 of them in the test split.
-- There is quite a small sample size with the overdrawn bad loans so taking the
-- numbers at face-value is unwise here. Producing confidence intervals would tell us
-- whether the results were due to a small-sample accident or whether they are 'genuine'.
-- The confidence intervals reveal that the results are not due to a small-sample accident
-- as the lower bound in the test-overdrawn category is almost 9 times larger than
-- the highest plausible rate for everyone else.
