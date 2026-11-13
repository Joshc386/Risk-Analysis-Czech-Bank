-- Correlation Matrix

-- The headline number. The bad rate among approved test loans falls from 8.5% to 2.4% (7 of 296). Nobody needs a P&L model to follow that, so lead with it. If you count Review as approved it's 2.7% (8 of 300); pick one and say which.
-- Why the rule loses money at high rates. This came out of the query I ran. At 12%, 8 of the 22 declined bad loans would still have been profitable: they repaid 76.8% of a total that is more than the principal. So "bad" loans aren't always loss-making. That's a strong point for explaining break-even.
-- Why test does better than train. On test the rule catches more bad loans (73% vs 52%). That's partly because test has more overdrawn bad loans (11 vs 9), not because the rule got better. It's an honest point to make.
-- Three caveats from the handoff aren't in the file:
-- The short-history Review rule is unvalidated: only 2 bad loans in test.
-- Running loans are right-censored. Point to the finished-loans sensitivity check.
-- Months overdrawn is n = 20, so the 100% bad rate rests on the Wilson CI, not on the raw rate.
WITH long AS (
  SELECT f.loan_id, m.measure, m.value
  FROM analytics.view_loan_features f
  CROSS JOIN LATERAL (VALUES
    ('affordability_ratio', f.affordability_ratio::float8),
    ('minimum_balance',     f.minimum_balance::float8),
    ('avg_balance',         f.avg_balance::float8),
    ('months_overdrawn',    f.months_overdrawn::float8),
    ('transactions',        f.transactions::float8),
    ('account_age_in_days', f.account_age_in_days::float8),
    ('age_at_loan',         f.age_at_loan::float8),
    ('is_bad',              f.is_bad::float8),
	('loan_amount', f.loan_amount::float8),
	('duration_months',f.duration_months::float8),
	('monthly_payment',f.monthly_payment::float8),
	('avg_monthly_income',f.avg_monthly_income::float8)
  ) AS m(measure, value)
  WHERE m.value IS NOT NULL
)
SELECT a.measure AS measure_x,
       b.measure AS measure_y,
       ROUND(CORR(a.value, b.value)::numeric, 2) AS correlation
FROM long a
JOIN long b ON a.loan_id = b.loan_id
GROUP BY a.measure, b.measure
ORDER BY correlation DESC;

-- Default rate by affordability ratio
WITH affordability_default AS (
SELECT period, affordability_ratio, months_history, NTILE (4) OVER (ORDER BY affordability_ratio DESC) AS affordability_band, is_bad
FROM analytics.view_loan_features
WHERE affordability_ratio IS NOT NULL AND months_history < 6
)
SELECT period, affordability_band, COUNT(*) AS loans, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY affordability_ratio) AS median_affordability,
SUM(is_bad) AS bad_loans,
ROUND(100.0*SUM(is_bad)/COUNT(*),2) AS default_rate
FROM affordability_default
GROUP BY period, affordability_band
ORDER BY period, affordability_band;

WITH thresholds AS (
SELECT generate_series(0.1,0.5,0.02) AS cutoff)
SELECT f.period, t.cutoff,
       COUNT(*)      FILTER (WHERE f.affordability_ratio > t.cutoff) AS flagged,
       SUM(f.is_bad) FILTER (WHERE f.affordability_ratio > t.cutoff) AS bad_caught,
       ROUND(100.0 * SUM(f.is_bad) FILTER (WHERE f.affordability_ratio > t.cutoff)
             / SUM(f.is_bad), 1) AS pct_bad_caught,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.affordability_ratio > t.cutoff AND f.is_bad = 0)
             / COUNT(*) FILTER (WHERE f.is_bad = 0), 1) AS pct_good_flagged,
       SUM(f.loan_amount) FILTER (WHERE f.affordability_ratio > t.cutoff AND f.is_bad = 1) AS bad_value_avoided,
       SUM(f.loan_amount) FILTER (WHERE f.affordability_ratio > t.cutoff AND f.is_bad = 0) AS good_value_declined
FROM thresholds t
CROSS JOIN analytics.view_loan_features f
WHERE f.affordability_ratio IS NOT NULL AND months_history < 6
GROUP BY f.period, t.cutoff
ORDER BY f.period, t.cutoff;


-- Default rate by minimum balance 
WITH banded AS (
SELECT minimum_balance, NTILE (4) OVER(ORDER BY minimum_balance DESC) AS min_balance_band, is_bad, months_history, account_age_in_days
FROM analytics.view_loan_features
WHERE minimum_balance IS NOT NULL
)

SELECT min_balance_band, MIN(minimum_balance) AS band_min, MAX(minimum_balance) AS band_max,
COUNT(*) AS loans, SUM(is_bad) AS bad_loans,
ROUND(100.0*SUM(is_bad)/COUNT(*),2) AS default_rate_pct, AVG(account_age_in_days) AS avg_account_age_days
FROM banded
WHERE months_history = 6
GROUP BY min_balance_band
ORDER BY min_balance_band;

-- Trade-off at each threshold value. Rule: decline if the minimum balance < cutoff value


WITH thresholds AS (
SELECT generate_series(0,10000,500) AS cutoff
),
threshold_vals AS (
SELECT f.period, t.cutoff,
       COUNT(*)      FILTER (WHERE f.minimum_balance < t.cutoff) AS flagged,
       SUM(f.is_bad) FILTER (WHERE f.minimum_balance < t.cutoff) AS bad_caught,
       ROUND(100.0 * SUM(f.is_bad) FILTER (WHERE f.minimum_balance < t.cutoff)
             / SUM(f.is_bad), 1) AS pct_bad_caught,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.minimum_balance < t.cutoff AND f.is_bad = 0)
             / COUNT(*) FILTER (WHERE f.is_bad = 0), 1) AS pct_good_flagged,
       SUM(f.loan_amount) FILTER (WHERE f.minimum_balance < t.cutoff AND f.is_bad = 1) AS bad_value_avoided,
       SUM(f.loan_amount) FILTER (WHERE f.minimum_balance < t.cutoff AND f.is_bad = 0) AS good_value_declined
FROM thresholds t
CROSS JOIN analytics.view_loan_features f
WHERE f.minimum_balance IS NOT NULL AND months_history = 6
GROUP BY f.period, t.cutoff
),
ratios AS (
SELECT *, bad_value_avoided/good_value_declined AS ratio FROM threshold_vals),
lgd_vals AS (
  SELECT generate_series(0.1,1,0.1) AS lgd
)
SELECT * FROM threshold_vals;


-- Sum the 'loan payment' transactions dated on or after the loan date then compute 1- sum(repaid)/sum(amount)
WITH repayments AS (
  SELECT loan.loan_id, loan.status, loan.amount, COALESCE(SUM(trans.amount),0) AS repaid
  FROM clean.loan
  LEFT JOIN clean.trans
  ON trans.account_id = loan.account_id AND trans.purpose = 'loan payment' AND trans.transaction_date >= loan.loan_date
  GROUP BY loan.loan_id, loan.status, loan.amount 
)
SELECT status, COUNT(*) AS loans, SUM(amount) AS loan_size, SUM(repaid) AS repaid,
       ROUND(1 - SUM(repaid) / SUM(amount), 3) AS unrepaid_share
FROM repayments
GROUP BY status
ORDER BY status;

-- Calculates the unrepaid share of different status loans.
-- Status B loans have an average of 23.2% unrepaid share 

WITH params AS (
  SELECT 7500 AS cutoff                   
-- Chose 7500 due to rejecting 70.6% of bad loans and only 5.8% of good loans. This threshold avoids lending out
-- CZK 219913 per loan that would be in bad loans and would forgo the interest earned on CZK 131690 per good loan. In the test set it rejects 78.6% of bad loans correctly and
-- incorrectly rejects 10.8% of good loans but the money not loaned out would have been CZK 794364 across 2 years.
),
groups AS (
  SELECT
    COUNT(*)      FILTER (WHERE f.minimum_balance <  p.cutoff) AS n1,
    SUM(f.is_bad) FILTER (WHERE f.minimum_balance <  p.cutoff) AS bad1,
    COUNT(*)      FILTER (WHERE f.minimum_balance >= p.cutoff) AS n2,
    SUM(f.is_bad) FILTER (WHERE f.minimum_balance >= p.cutoff) AS bad2
  FROM analytics.view_loan_features f
  CROSS JOIN params p
  WHERE f.period = 'test' AND f.months_history = 6
),
rates AS (
  SELECT *,
         bad1::numeric / n1                 AS p1,
         bad2::numeric / n2                 AS p2,
         (bad1 + bad2)::numeric / (n1 + n2) AS p_pool
  FROM groups
)
SELECT n1, bad1, ROUND(100 * p1, 1) AS rate_below_pct,
       n2, bad2, ROUND(100 * p2, 1) AS rate_above_pct,
       ROUND((p1 - p2) / SQRT(p_pool * (1 - p_pool) * (1.0/n1 + 1.0/n2)), 2) AS z,
       ROUND(100 * ((p1 - p2) - 1.96 * SQRT(p1*(1-p1)/n1 + p2*(1-p2)/n2)), 1) AS diff_ci_low_pct,
       ROUND(100 * ((p1 - p2) + 1.96 * SQRT(p1*(1-p1)/n1 + p2*(1-p2)/n2)), 1) AS diff_ci_high_pct
FROM rates;

-- The rule avoids CZK 5569596 of bad loan amount and declines 4775232 of good loan amount, creating 
-- a ratio of ~1.17.

-- Sensitivity check: does the 7500 rule hold on finished loans only?
SELECT period, 
CASE WHEN status IN ('A','B') THEN 'finished' ELSE 'running' END AS loan_state,
COUNT(*) AS loans, SUM(is_bad) AS bad,
ROUND(100.0 * SUM(is_bad) FILTER(WHERE minimum_balance < 7500)/NULLIF(SUM(is_bad),0),1) AS pct_bad_caught,
ROUND(100.0 * COUNT(*) FILTER (WHERE minimum_balance < 7500 AND is_bad = 0)
             / NULLIF(COUNT(*) FILTER (WHERE is_bad = 0), 0), 1)       AS pct_good_flagged
FROM analytics.view_loan_features
WHERE months_history = 6
GROUP BY period, loan_state
ORDER BY period, loan_state;


-- Age default rates

WITH age_bands AS (SELECT period, age_at_loan, NTILE(4) OVER(ORDER BY age_at_loan DESC) AS age_band, is_bad FROM analytics.view_loan_features
WHERE age_at_loan IS NOT NULL)
SELECT period, age_band, COUNT(*) AS loans, SUM(is_bad) AS bad_loans, MIN(age_at_loan) AS min_band_age, MAX(age_at_loan) AS max_band_age,
ROUND(100.0*SUM(is_bad)/COUNT(*),2) AS default_rate
FROM age_bands
GROUP BY period, age_band
ORDER BY period, age_band;

-- Account age
WITH account_age_bands AS (SELECT period, account_age_in_days, NTILE(4) OVER(ORDER BY account_age_in_days DESC) AS account_age_band, is_bad 
FROM analytics.view_loan_features
WHERE account_age_in_days IS NOT NULL)
SELECT account_age_band, COUNT(*) AS loans, SUM(is_bad) AS bad_loans, MIN(account_age_in_days) AS min_band_account_age,
MAX(account_age_in_days) AS max_band_account_age,
ROUND(AVG(account_age_in_days),1) AS average_age_in_band,
ROUND(100.0*SUM(is_bad)/COUNT(*),2) AS default_rate 
FROM account_age_bands
GROUP BY account_age_band
ORDER BY account_age_band;

WITH thresholds AS (
SELECT generate_series(150,700,50) AS cutoff
)
SELECT f.period, t.cutoff,
       COUNT(*)      FILTER (WHERE f.account_age_in_days < t.cutoff) AS flagged,
       SUM(f.is_bad) FILTER (WHERE f.account_age_in_days < t.cutoff) AS bad_caught,
       ROUND(100.0 * SUM(f.is_bad) FILTER (WHERE f.account_age_in_days < t.cutoff)
             / SUM(f.is_bad), 1) AS pct_bad_caught,
       ROUND(100.0 * COUNT(*) FILTER (WHERE f.account_age_in_days < t.cutoff AND f.is_bad = 0)
             / COUNT(*) FILTER (WHERE f.is_bad = 0), 1) AS pct_good_flagged,
       SUM(f.loan_amount) FILTER (WHERE f.account_age_in_days < t.cutoff AND f.is_bad = 1) AS bad_value_avoided,
       SUM(f.loan_amount) FILTER (WHERE f.account_age_in_days < t.cutoff AND f.is_bad = 0) AS good_value_declined
FROM thresholds t
CROSS JOIN analytics.view_loan_features f
WHERE f.account_age_in_days IS NOT NULL
GROUP BY f.period, t.cutoff
ORDER BY f.period, t.cutoff;


-- Months Overdrawn
WITH flag AS (
SELECT period, (months_overdrawn > 0) AS ever_overdrawn,
COUNT(*) AS loans, SUM(is_bad) AS bad_loans,
COUNT(*) FILTER(WHERE status = 'B') AS finished_bad_loans,
COUNT(*) FILTER(WHERE status = 'D') AS running_bad_loans,
SUM(is_bad)::numeric/COUNT(*) AS p
FROM analytics.view_loan_features
GROUP BY period, ever_overdrawn
)
SELECT period, ever_overdrawn, loans, bad_loans, finished_bad_loans, running_bad_loans,
ROUND(100 * p, 1) AS bad_loan_rate,
ROUND((100 * ((p + 1.96^2/(2*loans))
              - 1.96 * SQRT(p*(1-p)/loans + 1.96^2/(4*loans^2)))
              / (1 + 1.96^2/loans))::numeric, 1) AS ci_low_pct,
       ROUND((100 * ((p + 1.96^2/(2*loans))
              + 1.96 * SQRT(p*(1-p)/loans + 1.96^2/(4*loans^2)))
              / (1 + 1.96^2/loans))::numeric, 1) AS ci_high_pct
FROM flag
ORDER BY period, ever_overdrawn;
;

-- All overdrawn loans are on mature accounts with a -ve minimum balance

SELECT duration_months, period, COUNT(*) AS loans,
COUNT(*) FILTER(WHERE status = 'B') AS defaulted_loans,
SUM(is_bad) AS bad_loans,
ROUND(AVG(loan_amount),1) AS average_loan_amount,
ROUND(100.0 * COUNT(*) FILTER(WHERE status = 'B')/COUNT(*),1) AS default_rate,
ROUND(100.0 * SUM(is_bad)/COUNT(*),1) AS bad_loan_rate
FROM analytics.view_loan_features
GROUP BY period, duration_months
ORDER BY period, duration_months;


-- District
SELECT salary_category, COUNT(DISTINCT(district_id)) AS districts,
COUNT(*) AS loans, ROUND(100.0 * COUNT(*)/SUM(COUNT(*)) OVER(),1) AS pct_of_all_loans
FROM analytics.view_loan_features
GROUP BY salary_category;

SELECT COUNT(*) AS loans, SUM(is_bad) AS bad_loans, district_name, avg_salary
FROM analytics.view_loan_features
GROUP BY district_name, avg_salary
ORDER BY loans DESC;

-- Difficult to look at each district properly due to the fact that some have very 
-- few loans taken out across the 6-year period. Most have 10 or less

WITH banded AS (
  SELECT avg_salary, is_bad,
  CEIL(4* CUME_DIST() OVER(ORDER BY avg_salary DESC)) AS salary_band,
  district_name
  FROM analytics.view_loan_features
)
SELECT salary_band, COUNT(*) AS loan, SUM(is_bad) AS bad_loans,
ROUND(100.0 * SUM(is_bad)/COUNT(*),1) AS bad_rate, MIN(avg_salary) AS mimimum,
MAX(avg_salary) AS maximum
FROM banded
GROUP BY salary_band
ORDER BY salary_band;

-- This shows there to be no real salary effect due to the different districts


SELECT ROUND(AVG(salary_band),1) AS avg_salary_band, avg_salary,
district_name FROM banded
GROUP BY avg_salary, district_name
ORDER BY avg_salary DESC;

-- Prague band 1 and 2
-- Band salaries by each district rather than overall across all
SELECT avg_salary, district_name
FROM analytics.view_loan_features
GROUP BY district_name, avg_salary
ORDER BY avg_salary DESC;

-- THE RULE
WITH rule AS (SELECT period, is_bad AS bad_loan, loan_amount, monthly_payment, duration_months,
CASE
WHEN months_overdrawn > 0 THEN 'Decline'
WHEN months_history = 6 AND minimum_balance < 7500 THEN 'Decline'
WHEN months_history < 6 AND affordability_ratio > 0.3 THEN 'Review'
ELSE 'Approve' END AS decision
FROM analytics.view_loan_features
),
summary AS (
SELECT period,
COUNT(*) FILTER (WHERE bad_loan = 1) AS bad_loans,
COUNT(*) FILTER (WHERE bad_loan = 0) AS good_loans,
COUNT(*) FILTER (WHERE bad_loan = 1 AND decision = 'Decline') AS bad_declined,
COUNT(*) FILTER (WHERE bad_loan = 0 AND decision = 'Decline') AS good_declined,
COUNT(*) FILTER (WHERE decision = 'Review') AS reviewed,
SUM(loan_amount) FILTER (WHERE bad_loan = 1) AS bad_value,
SUM(loan_amount) FILTER (WHERE bad_loan = 0) AS good_value,
SUM(loan_amount) FILTER (WHERE bad_loan = 1 AND decision = 'Decline') AS bad_value_declined,
SUM(loan_amount) FILTER (WHERE bad_loan = 0 AND decision = 'Decline') AS good_value_declined
FROM rule
GROUP BY period
)

SELECT period, bad_loans, bad_declined, good_loans, good_declined, reviewed,
ROUND(100.0 * bad_declined / bad_loans, 1) AS pct_bad_declined,
ROUND(100.0 * good_declined / good_loans, 1) AS pct_good_declined,
good_value, good_value_declined, bad_value, bad_value_declined, bad_value - bad_value_declined AS bad_value_approved,
good_value - good_value_declined AS good_value_approved,
ROUND(100.0 * bad_value_declined / bad_value, 1) AS pct_bad_value_declined,
ROUND(100.0 * good_value_declined / good_value, 1) AS pct_good_value_declined
FROM summary
ORDER BY period;

WITH rule AS (SELECT period, is_bad AS bad_loan, loan_amount, monthly_payment, duration_months,
CASE
WHEN months_overdrawn > 0 THEN 'Decline'
WHEN months_history = 6 AND minimum_balance < 7500 THEN 'Decline'
WHEN months_history < 6 AND affordability_ratio > 0.3 THEN 'Review'
ELSE 'Approve' END AS decision
FROM analytics.view_loan_features
WHERE period = 'test'
),
rates AS (
  SELECT generate_series(0.00, 0.08, 0.001) AS annual_rate 
),
principal_calc AS (
  SELECT rates.annual_rate, rule.period, rule.bad_loan, rule.decision, rule.loan_amount,
  CASE WHEN rates.annual_rate = 0 THEN rule.loan_amount
  ELSE rule.monthly_payment * (1 - POWER(1 + rates.annual_rate/12, -rule.duration_months))/(rates.annual_rate/12)
  END AS principal -- Principal formula
  FROM rule
  CROSS JOIN rates
),
loan_profit AS (
  SELECT annual_rate, bad_loan, decision,
  CASE WHEN bad_loan = 1 THEN -(principal - 0.768*loan_amount)
  ELSE loan_amount - principal END AS profit
  FROM principal_calc
),
break_even AS (
SELECT annual_rate,
ROUND(SUM(profit) FILTER (WHERE bad_loan = 1)) AS approve_all_bad_cost,
ROUND(SUM(profit)) AS approve_all_profit,
ROUND(SUM(profit) FILTER (WHERE bad_loan = 1 AND decision <> 'Decline')) AS rule_bad_cost,
ROUND(SUM(profit) FILTER (WHERE decision <> 'Decline')) AS rule_profit,
ROUND(SUM(profit) FILTER (WHERE decision <> 'Decline') - SUM(profit)) AS rule_vs_approve_all
FROM loan_profit
GROUP BY annual_rate
ORDER BY annual_rate
)
SELECT * FROM break_even
;
