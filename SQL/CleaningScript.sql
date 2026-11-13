ROLLBACK;
BEGIN;

DROP SCHEMA IF EXISTS clean CASCADE;
DROP SCHEMA IF EXISTS ref CASCADE;

CREATE SCHEMA ref;
CREATE SCHEMA clean;

CREATE TABLE clean.district (
  district_id             INTEGER PRIMARY KEY,
  district_name           TEXT    NOT NULL,
  region                  TEXT    NOT NULL,
  inhabitants             INTEGER NOT NULL,
  munis_under_500         INTEGER NOT NULL,
  munis_500_1999          INTEGER NOT NULL,
  munis_2000_9999         INTEGER NOT NULL,
  munis_over_10000        INTEGER NOT NULL,
  num_cities              INTEGER NOT NULL,
  urban_ratio_pct         NUMERIC NOT NULL,
  avg_salary              NUMERIC NOT NULL,
  unemployment_95_pct     NUMERIC,
  unemployment_96_pct     NUMERIC NOT NULL,
  entrepreneurs_per_1000  INTEGER NOT NULL,
  crimes_95               INTEGER,
  crimes_96               INTEGER NOT NULL
);

INSERT INTO clean.district
SELECT
  district_id,
  TRIM(district_name),
  TRIM(region),
  no_of_inhabitants,
  no_of_municipalities_w_inhabitants_less_499,
  no_of_municipalities_w_inhabitants_500_1999,
  no_of_municipalities_w_inhabitants_2000_9999,
  no_of_municipalities_w_inhabitants_larger_10000,
  no_of_cities,
  ration_of_urban_inhabitants,
  average_salary,
  unemployment_rate_1995,
  unemployment_rate_1996,
  no_of_entrepreneurs_per_1000,
  no_of_crimes_committed_1995,
  no_of_crimes_committed_1996
FROM raw.district;


CREATE TABLE clean.account(
account_id INTEGER PRIMARY KEY,
district_id INTEGER NOT NULL REFERENCES clean.district(district_id),
frequency TEXT NOT NULL,
opened_date DATE NOT NULL
CONSTRAINT check_account_opened_range
CHECK(opened_date BETWEEN '1993-01-01' AND '1998-12-31')
);

INSERT INTO clean.account
SELECT 
account_id, district_id, 
CASE TRIM(frequency)
WHEN 'POPLATEK MESCINE' THEN 'monthly'
WHEN 'POPLATEK TYDNE' THEN 'weekly'
WHEN 'POPLATEK PO OBRATU' THEN 'after transaction'
END,
to_date(TRIM(opened_date), 'YYMMDD')
FROM raw.account;

CREATE TABLE clean.client(
client_id INTEGER PRIMARY KEY,
birth_date DATE NOT NULL CONSTRAINT check_client_birthdate CHECK (birth_date < '1999-01-01'),
gender TEXT NOT NULL CONSTRAINT check_client_gender CHECK (gender IN ('M','F')),
district_id INTEGER NOT NULL REFERENCES clean.district (district_id)
);

WITH parts AS (
SELECT client_id, district_id, 1900 + LEFT(LPAD(birth_number::text,6,'0'),2)::int AS birth_year,
SUBSTRING(LPAD(birth_number::text, 6, '0'),3,2)::int AS coded_month,
RIGHT(LPAD(birth_number::text, 6, '0'),2)::int AS birth_day
FROM raw.client
)
INSERT INTO clean.client
SELECT client_id, make_date(birth_year, CASE WHEN coded_month > 50 THEN coded_month - 50 ELSE coded_month END, birth_day),
CASE WHEN coded_month > 50 THEN 'F' ELSE 'M' END,
district_id FROM parts;

CREATE TABLE clean.disp(
disp_id INTEGER PRIMARY KEY,
client_id INTEGER NOT NULL REFERENCES clean.client(client_id),
account_id INTEGER NOT NULL REFERENCES clean.account(account_id),
role TEXT NOT NULL
);

INSERT INTO clean.disp
SELECT disp_id, client_id, account_id, CASE(TRIM(type)) WHEN 'OWNER' THEN 'owner' WHEN 'DISPONENT' THEN 'authorised' END
FROM raw.disp;

CREATE TABLE clean.card(
card_id INTEGER PRIMARY KEY,
disp_id INTEGER NOT NULL REFERENCES clean.disp(disp_id),
card_type TEXT NOT NULL CONSTRAINT check_card_type CHECK (card_type IN ('junior', 'classic','gold')),
issued DATE NOT NULL CONSTRAINT check_card_issued_range CHECK (issued BETWEEN '1993-01-01' AND '1998-12-31')
);

INSERT INTO clean.card
SELECT card_id, disp_id, type, to_date(issued,'YYMMDD')
FROM raw.card;

CREATE TABLE clean.loan (
  loan_id          INTEGER PRIMARY KEY,
  account_id       INTEGER NOT NULL REFERENCES clean.account (account_id),
  loan_date        DATE    NOT NULL,
  amount           NUMERIC NOT NULL CHECK (amount > 0),
  duration_months  INTEGER NOT NULL CHECK (duration_months IN (12,24,36,48,60)),
  monthly_payment  NUMERIC NOT NULL CHECK (monthly_payment > 0),
  status           TEXT    NOT NULL CHECK (status IN ('A', 'B', 'C', 'D')),
  status_label     TEXT    NOT NULL
);

INSERT INTO clean.loan
SELECT
  loan_id,
  account_id,
  loan_date,
  amount,
  duration,
  payments,
  TRIM(status),
  CASE TRIM(status)
    WHEN 'A' THEN 'finished, paid'
    WHEN 'B' THEN 'finished, unpaid'
    WHEN 'C' THEN 'running, on track'
    WHEN 'D' THEN 'running, in debt'
  END
FROM raw.loan;


CREATE TABLE clean.standing_order (
  order_id           INTEGER PRIMARY KEY,
  account_id         INTEGER NOT NULL REFERENCES clean.account (account_id),
  recipient_bank     TEXT    NOT NULL,
  recipient_account  TEXT    NOT NULL,
  amount             NUMERIC NOT NULL,
  purpose            TEXT
);
 
INSERT INTO clean.standing_order
SELECT
  order_id,
  account_id,
  TRIM(bank_to),
  TRIM(account_to),
  amount,
  CASE TRIM(k_symbol)
    WHEN 'POJISTNE' THEN 'insurance'
    WHEN 'SIPO'     THEN 'household bills'
    WHEN 'LEASING'  THEN 'leasing'
    WHEN 'UVER'     THEN 'loan payment'
  END
FROM raw.order;


CREATE TABLE clean.trans (
  trans_id         INTEGER PRIMARY KEY,
  account_id       INTEGER NOT NULL REFERENCES clean.account (account_id),
  transaction_date       DATE    NOT NULL,
  direction        TEXT    NOT NULL,
  operation        TEXT,
  amount           NUMERIC NOT NULL,
  signed_amount    NUMERIC NOT NULL,
  balance          NUMERIC NOT NULL,
  purpose          TEXT,
  partner_bank     TEXT,
  partner_account  TEXT
);
 
INSERT INTO clean.trans
SELECT
  trans_id,
  account_id,
  transaction_date,
  CASE TRIM(type)
    WHEN 'PRIJEM' THEN 'credit'
    WHEN 'VYDAJ'  THEN 'debit'
    WHEN 'VYBER'  THEN 'debit'
  END,
  CASE TRIM(operation)
    WHEN 'VKLAD'          THEN 'cash deposit'
    WHEN 'VYBER'          THEN 'cash withdrawal'
    WHEN 'VYBER KARTOU'   THEN 'card withdrawal'
    WHEN 'PREVOD Z UCTU'  THEN 'transfer in'
    WHEN 'PREVOD NA UCET' THEN 'transfer out'
  END,
  amount,
  CASE WHEN TRIM(type) = 'PRIJEM' THEN amount ELSE -amount END,
  balance,
  CASE TRIM(k_symbol)
    WHEN 'POJISTNE'    THEN 'insurance'
    WHEN 'SLUZBY'      THEN 'statement fee'
    WHEN 'UROK'        THEN 'interest credited'
    WHEN 'SANKC. UROK' THEN 'penalty interest'
    WHEN 'SIPO'        THEN 'household bills'
    WHEN 'DUCHOD'      THEN 'pension'
    WHEN 'UVER'        THEN 'loan payment'
  END,
  NULLIF(TRIM(bank), ''),
  account::text
FROM raw.trans;
COMMIT;
