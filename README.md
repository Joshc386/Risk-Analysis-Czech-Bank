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

There are 682 loans in total with a total loaned out of £103261740 and there are 76 'bad' loans that total to £15580152, whereby a bad loan is deemed as one with a status of B or D. B means the loan was not paid back and D means the loan is on-track to not be paid which gives an overall default rate of 11.1%. In the data there are 4500 accounts linked to Berka bank but only 682 of them have taken out loans.

# Analysis

# Views
The purpose of this is to create the necessary tables in order to create the correct visuals in Power BI. The reason views are used is due to the fact that the raw tables are not ideal for visualising and telling the appropriate story about the data. A view allows us to see a different side of the raw data ad the views have been catered to visualise the most important data/metrics.
