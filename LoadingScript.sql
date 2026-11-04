BEGIN;
CREATE SCHEMA raw;
CREATE TABLE raw.account(
account_id INTEGER,
district_id INTEGER,
frequency TEXT,
opened_date TEXT
);
CREATE TABLE raw.card(
card_id INTEGER,
disp_id INTEGER,
type TEXT,
issued TEXT
);
CREATE TABLE raw.client(
client_id INTEGER,
birth_number INTEGER,
district_id INTEGER
);
CREATE TABLE raw.disp(
disp_id INTEGER,
client_id INTEGER,
account_id INTEGER,
type TEXT
);
CREATE TABLE raw.district(
district_id INTEGER,
district_name TEXT,
region TEXT,
no_of_inhabitants INTEGER,
no_of_municipalities_w_inhabitants_less_499 INTEGER,
no_of_municipalities_w_inhabitants_500_1999 INTEGER,
no_of_municipalities_w_inhabitants_2000_9999 INTEGER,
no_of_municipalities_w_inhabitants_larger_10000 INTEGER,
no_of_cities INTEGER,
ration_of_urban_inhabitants NUMERIC,
average_salary NUMERIC,
unemployment_rate_1995 NUMERIC,
unemployment_rate_1996 NUMERIC,
no_of_entrepreneurs_per_1000 INTEGER,
no_of_crimes_committed_1995 INTEGER,
no_of_crimes_committed_1996 INTEGER
);
CREATE TABLE raw.loan(
loan_id INTEGER,
account_id INTEGER,
loan_date DATE,
amount NUMERIC,
duration INTEGER,
payments NUMERIC,
status TEXT
);
CREATE TABLE raw.order(
order_id INTEGER,
account_id INTEGER,
bank_to TEXT,
account_to TEXT,
amount NUMERIC,
k_symbol TEXT
);
CREATE TABLE raw.trans(
trans_id INTEGER,
account_id INTEGER,
transaction_date DATE,
type TEXT,
operation TEXT,
amount NUMERIC,
balance NUMERIC,
k_symbol TEXT,
bank TEXT,
account INTEGER
);
COMMIT;
