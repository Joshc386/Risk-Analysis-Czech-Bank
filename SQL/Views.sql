BEGIN;
DROP SCHEMA IF EXISTS analytics CASCADE;
CREATE SCHEMA analytics;

CREATE VIEW analytics.view_district AS 
SELECT district_id, district_name, inhabitants, unemployment_95_pct, unemployment_96_pct, avg_salary, NTILE(4) OVER(ORDER BY avg_salary DESC) AS salary_category
FROM clean.district;

CREATE VIEW analytics.view_loan_base AS 
SELECT client_id, loan.account_id, analytics.view_district.district_id, district_name, loan_id, loan_date, amount AS loan_amount, duration_months, monthly_payment,
status, frequency, inhabitants, unemployment_95_pct, unemployment_96_pct, avg_salary, salary_category, disp_id, birth_date, gender, EXTRACT(YEAR FROM AGE(loan_date, birth_date)) AS age_at_loan,
CASE
WHEN status IN ('B','D') THEN 1 ELSE 0 END AS is_bad,
CASE WHEN loan_date < '1997-01-01' THEN 'train' ELSE 'test' END AS period
-- Splits loans into pre and post 97 due to most loans in 97 and 98 not yet being paid/completed
FROM clean.loan
LEFT JOIN clean.account
USING(account_id)
LEFT JOIN analytics.view_district
USING(district_id)
LEFT JOIN clean.disp
ON disp.account_id = loan.account_id AND disp.role = 'owner'
LEFT JOIN clean.client
USING(client_id);

CREATE VIEW analytics.view_pre_loan AS 
WITH loan_profile AS (SELECT loan.*, district_id,
account.opened_date,
LEAST(6, (loan_date - opened_date)/30.0) AS months_history,
SUM(trans.amount) FILTER(WHERE trans.direction = 'credit') AS six_m_credit,
ROUND(AVG(trans.balance),2) AS avg_balance,
MIN(trans.balance) AS minimum_balance,
COUNT(trans.trans_id) AS transactions,
loan_date - account.opened_date AS account_age_in_days,
COUNT(DISTINCT date_trunc('month',trans.transaction_date)) FILTER(WHERE trans.balance < 0) AS months_overdrawn
FROM clean.loan
LEFT JOIN clean.account USING(account_id)
LEFT JOIN clean.trans
ON trans.account_id = loan.account_id
AND trans.transaction_date >= loan.loan_date - INTERVAL '6 months'
AND trans.transaction_date < loan.loan_date -- Keep data from after the loan excluded
GROUP BY loan.loan_id, account.account_id),

monthly_income AS (
SELECT *, ROUND(six_m_credit / NULLIF(months_history, 0),2) AS avg_monthly_income
FROM loan_profile),

affordability AS (
SELECT *, monthly_payment/NULLIF(avg_monthly_income,0) AS affordability_ratio
FROM monthly_income), -- Larger value means less affordable. > 1 means monthly payment is more than monthly income

card AS (
SELECT * FROM affordability
LEFT JOIN clean.disp
USING(account_id)
LEFT JOIN clean.card
USING(disp_id)
WHERE role = 'owner'
),

complete_loan_profile AS (
SELECT *,
CASE WHEN issued <= loan_date THEN 1 ELSE 0 END AS had_card_before_loan
FROM card)
SELECT loan_id, months_history, six_m_credit, avg_monthly_income, affordability_ratio,
avg_balance, minimum_balance, transactions, months_overdrawn, account_age_in_days,
had_card_before_loan
FROM complete_loan_profile;

CREATE VIEW analytics.view_loan_features AS 
SELECT base.*, pre.months_history, pre.avg_monthly_income, pre.affordability_ratio,
pre.avg_balance, pre.minimum_balance, pre.transactions,
pre.months_overdrawn, pre.account_age_in_days, pre.had_card_before_loan
FROM analytics.view_loan_base base
JOIN analytics.view_pre_loan pre USING(loan_id);
COMMIT;

