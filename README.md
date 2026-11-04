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
This was done in the 'Preliminary.sql' file and essentially was used to explore the data and produce some summary statistics and assess the structure fully. There are 8 tables 
