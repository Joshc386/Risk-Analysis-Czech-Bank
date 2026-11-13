-- Total no. of loans: SELECT COUNT(*) AS total_loans FROM clean.loan

-- Total amount loaned out: SELECT SUM(amount) AS total_loaned_out FROM clean.loan

-- Total number of defaulted loans: SELECT COUNT(*) FROM clean.loan
-- WHERE status = 'B' OR status = 'D'

-- Overall default rate
-- SELECT ROUND(100*COUNT(*) FILTER(WHERE status IN ('B', 'D'))::NUMERIC/COUNT(*),2) AS default_rate
-- FROM clean.loan

-- Default rates by year
WITH updated_loans AS (
SELECT *, EXTRACT(YEAR FROM loan_date) AS issue_year,
NTILE(5) OVER(ORDER BY amount) AS loan_amount_band,
NTILE(5) OVER(ORDER BY monthly_payment) AS monthly_payment_band FROM clean.loan
),
-- SELECT year, ROUND(100*COUNT(*) FILTER(WHERE status IN ('B','D'))::NUMERIC/COUNT(*),2) AS default_rate,
-- SUM(amount) AS total_loaned_out,
-- SUM(amount) FILTER(WHERE status IN ('B','D')) AS total_loaned_out_defaulted
-- FROM yearly_view
-- GROUP BY issue_year

-- Default rate by loan amount band
-- SELECT loan_amount_band, ROUND(100*COUNT(*) FILTER(WHERE status IN ('B','D'))::NUMERIC/COUNT(*),2) AS default_rate
-- FROM updated_loans
-- GROUP BY loan_amount_band
-- ORDER BY loan_amount_band

-- Default rate by loan duration
-- SELECT duration_months, ROUND(100*COUNT(*) FILTER(WHERE status IN ('B','D'))::NUMERIC/COUNT(*),2) AS default_rate
-- FROM updated_loans
-- GROUP BY duration_months
-- ORDER BY duration_months

-- Default rate by monthly payment band
-- SELECT monthly_payment_band, COUNT(*) AS total_loans, ROUND(100*COUNT(*) FILTER(WHERE status IN ('B','D'))::NUMERIC/COUNT(*),2) AS default_rate
-- FROM updated_loans
-- GROUP BY monthly_payment_band
-- ORDER BY monthly_payment_band

filtered_district AS (
SELECT district_id, inhabitants, unemployment_95_pct, unemployment_96_pct, avg_salary, NTILE(10) OVER(ORDER BY avg_salary DESC) AS salary_category FROM clean.district
),
account_district AS (
SELECT * FROM clean.account
LEFT JOIN filtered_district
USING(district_id)
),
loan_profile AS (
SELECT client_id, loan.account_id, filtered_district.district_id, loan_id, loan_date, amount AS loan_amount, duration_months, monthly_payment,
status, frequency, inhabitants, unemployment_95_pct, unemployment_96_pct, avg_salary, salary_category, disp_id, birth_date, gender, EXTRACT(YEAR FROM AGE(loan_date, birth_date))::int AS age_at_loan,
CASE
WHEN status IN ('B','D') THEN 1 ELSE 0 END AS is_bad
FROM clean.loan
LEFT JOIN clean.account
USING(account_id)
LEFT JOIN filtered_district
USING(district_id)
LEFT JOIN clean.disp
ON disp.account_id = loan.account_id AND disp.role = 'owner'
LEFT JOIN clean.client
USING(client_id)
)
SELECT * FROM loan_profile