SELECT 'district' AS table, (SELECT COUNT(*) FROM raw.district) AS raw_rows, (SELECT COUNT(*) FROM clean.district) AS clean_rows
UNION ALL SELECT 'account',        (SELECT COUNT(*) FROM raw.account), (SELECT COUNT(*) FROM clean.account)
UNION ALL SELECT 'client',         (SELECT COUNT(*) FROM raw.client),  (SELECT COUNT(*) FROM clean.client)
UNION ALL SELECT 'disp',           (SELECT COUNT(*) FROM raw.disp),    (SELECT COUNT(*) FROM clean.disp)
UNION ALL SELECT 'card',           (SELECT COUNT(*) FROM raw.card),    (SELECT COUNT(*) FROM clean.card)
UNION ALL SELECT 'loan',           (SELECT COUNT(*) FROM raw.loan),    (SELECT COUNT(*) FROM clean.loan)
UNION ALL SELECT 'standing_order', (SELECT COUNT(*) FROM raw."order"), (SELECT COUNT(*) FROM clean.standing_order)
UNION ALL SELECT 'trans',          (SELECT COUNT(*) FROM raw.trans),   (SELECT COUNT(*) FROM clean.trans);

SELECT MIN(trans_date), MAX(trans_date) FROM clean.trans;
SELECT MIN(loan_date),  MAX(loan_date)  FROM clean.loan;
SELECT MIN(birth_date), MAX(birth_date) FROM clean.client;