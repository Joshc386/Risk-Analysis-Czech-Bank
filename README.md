# Risk Analysis of a Czech Bank

### What pre-loan account characteristics indicate the probability of a loan going bad? Can these be encoded into a single rule?
This project aims to build a rule that this bank can use to filter loan applications into 3 different categories: 'Approve', 'Decline' or 'Review' given the applicant's historical data.
It will serve as a screening/filtering aid for the bank's loan officers

## Key Findings
- 11.1% of all loans are rated as 'bad' loans, with 30 of them occurring in 1997-1998 and 46 of them occurring in 1993-1996.

- Using the discovered rule earns the bank more than approving every application if the bank's lending margin is below 7% a year.

- 100% of accounts with at least 1 month of overdraft prior to the loan being taken out had bad-rated loans (20 of the 76 bad loans).

- The rule catches 73.3% of bad loans and declines only 9.9% of good loans in the test dataset.

## Results
The final rule was determined using 4 metrics: months_overdrawn, months_history, minimum_balance and the affordability ratio.
Conditions for a 'Decline' rating:
- `months_overdrawn > 0`, `months_history = 6` and `minimum_balance < 7500`

Conditions for a 'Review' rating:
- `affordability_ratio > 0.3 AND months_history < 6`

Otherwise, the loan is rated as 'Approve'.

This rule catches 73.3% of the bad loans and 9.9% of good loans are flagged in the test dataset, which would have flagged CZK 4,775,232 worth of good loan value to be declined and CZK 5,569,596 worth of bad value to be flagged to be declined. If the bank's lending margin drops below 7% a year, using the rule earns more than approving every application. Above 7% the interest given up on wrongly declined good loans outweighs the losses avoided on bad loans. The data has no interest rates or loan principals so these had to be calculated through using each loan's monthly payment at an assumed rate and using the 23.2% loss rate, measured from the unrepaid share of all finished bad loans.
Using an interest rate of 5.5% rule is also profitable compared to approving all loans by CZK 250,773 which is **6.66%** more profitable at an assumed 5.5% margin, showing that the rule would have actually worked on the test data.
The rule also avoids 74.6% of bad-loan losses at a 5.5% margin compared to if all loans were approved, reinforcing the point of the rule actually being effective.

| Assumed annual margin | Rule vs approve-all (CZK, 1997–98 loans) |
|:---|---:|
| 0.0% | +1,292,146 |
| 2.0% | +894,112 |
| 4.0% | +518,576 |
| 5.5% | +250,773 |
| 6.9% | +10,944 |
| 7.0% | −5,825 |

## Definitions
- Bad loan: this is defined as a loan given a status of 'B' or 'D' where status B defines a loan that has finished and was not fully repaid and status D is a loan that is still running and the client is in debt.

- Train/test split: the data was split into a training set and a test set to verify the performance of the rule. The training data spans all loans from 1993 - 1996 inclusive and the test data spans loans from 1997-1998 inclusive.

- `months_history`: in the code this is only used as `= 6` or `> 6` but where it says `= 6` this means at least a 6-month history with the bank and defines more mature accounts with the bank.

## Data
The original data source can be located here and is publicly available to be downloaded [here](https://www.kaggle.com/datasets/marceloventura/the-berka-dataset?) and the page defining the tables and columns is located on at [this location](https://webpages.charlotte.edu/mirsad/itcs6265/group1/index.html) .

Further detail about the SQL code and logic behind the decisions I made is available via the [methodology page] (Methodology.md).
