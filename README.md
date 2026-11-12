# Risk Analysis of a Czech Bank

### What pre-loan account characteristics indicate the probability of a loan going bad? Can these be encoded into a single rule?
This project aims to build a rule that this bank can use to filter loan applications into 3 different categories: 'Approve', 'Decline' or 'Review' given the applicant's historical data.
It will serve as the bank's primary decision maker when figuring out whether to lend to an individual or not.

## Key Findings
/item 11.1% of all loans are rated as 'bad' loans, with 30 of them occurring in 1997-1998 and 46 of them occurring in 1993-1996.

/item For accounts with at least 6 months history at the bank in the lowest quarter of all accounts in terms of the lowest minimum balance recorded have a default rate of 50.56%.

/item The bank requires an interest rate on their loans of between 6.9% and 7% on all of their loans to break even, given the ratio of bad-to-good loans and the defaulted loans
not paying back 23.2% of the loan on average.

/item 100% of accounts with at least 1 month of overdraft prior to the loan being taken out had bad-rated loans (20 of the 76 bad loans).

/item Using just a minimum balance filter of accounts with a minimum balance of less than 7500 correctly flagged 78.6% of bad loans in the test dataset whilst only flagging 10.8% of good loans incorrectly.

/item The rule catches 73.3% of bad loans and declines only 9.9% of good loans in the test dataset.

## Results
The final rule was determined using 4 metrics: months_overdrawn, months_history, minimum_balance and the affordability ratio.
Conditions for a 'Decline' rating:
/item `months_overdrawn > 0`
/item `months_history = 6`
/item `minimum_balance < 7500`

Conditions for a 'Review' rating:
/item `affordability_ratio > 0.3 AND months_history < 6`
A loan with figures outside of these conditions were give an 'Approve' rating.

Anything else: 'Approved'.

This rule catches 73.3% of the bad loans and 9.9% of good loans are flagged in the test dataset, resulting in CZK5569596 of bad value being declined and CZK
