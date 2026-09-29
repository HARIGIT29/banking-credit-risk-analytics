-- 02_load_dataset.sql
-- Import the cleaned CSV. The CSV has 43 columns; only the 25 base fields
-- are loaded into credit_clients_raw. The 18 derived fields are read into
-- session variables and intentionally ignored by the SQL base table.

USE banking_credit_risk;

-- LOAD01 | Reset base table before deterministic reload
TRUNCATE TABLE credit_clients_raw;

-- LOAD02 | Import cleaned dataset
LOAD DATA LOCAL INFILE 'C:/Users/Hariiii/Downloads/Retail_Banking_Credit_Risk_Analytics_PORTFOLIO_READY_FINAL/data/cleaned/banking_credit_risk_cleaned.csv'
INTO TABLE credit_clients_raw
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(
    @ID, @LIMIT_BAL, @SEX, @EDUCATION, @MARRIAGE, @AGE,
    @PAY_0, @PAY_2, @PAY_3, @PAY_4, @PAY_5, @PAY_6,
    @BILL_AMT1, @BILL_AMT2, @BILL_AMT3, @BILL_AMT4, @BILL_AMT5, @BILL_AMT6,
    @PAY_AMT1, @PAY_AMT2, @PAY_AMT3, @PAY_AMT4, @PAY_AMT5, @PAY_AMT6,
    @DefaultFlag,
    @Avg_Bill_6M, @Avg_Payment_6M, @Credit_Utilization,
    @Payment_to_Bill_Ratio_Valid, @Bill_Amount_Status, @Payment_vs_Bill_Status,
    @PAY_0_Delayed, @PAY_2_Delayed, @PAY_3_Delayed, @PAY_4_Delayed, @PAY_5_Delayed, @PAY_6_Delayed,
    @Delinquency_Count, @Max_Delinquency_Code, @Default_Label, @Age_Group,
    @Credit_Limit_Band, @Utilization_Band
)
SET
    ID=@ID,
    LIMIT_BAL=@LIMIT_BAL,
    SEX=@SEX,
    EDUCATION=@EDUCATION,
    MARRIAGE=@MARRIAGE,
    AGE=@AGE,
    PAY_0=@PAY_0,
    PAY_2=@PAY_2,
    PAY_3=@PAY_3,
    PAY_4=@PAY_4,
    PAY_5=@PAY_5,
    PAY_6=@PAY_6,
    BILL_AMT1=@BILL_AMT1,
    BILL_AMT2=@BILL_AMT2,
    BILL_AMT3=@BILL_AMT3,
    BILL_AMT4=@BILL_AMT4,
    BILL_AMT5=@BILL_AMT5,
    BILL_AMT6=@BILL_AMT6,
    PAY_AMT1=@PAY_AMT1,
    PAY_AMT2=@PAY_AMT2,
    PAY_AMT3=@PAY_AMT3,
    PAY_AMT4=@PAY_AMT4,
    PAY_AMT5=@PAY_AMT5,
    PAY_AMT6=@PAY_AMT6,
    DefaultFlag=@DefaultFlag;

-- LOAD03 | Verify import
SELECT COUNT(*) AS total_rows, COUNT(DISTINCT ID) AS customers FROM credit_clients_raw;



