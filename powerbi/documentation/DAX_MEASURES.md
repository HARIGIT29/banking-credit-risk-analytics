# DAX Measures — Final Release

Measures are defined in `Retail_Banking_Credit_Risk_Analytics.SemanticModel/definition/tables/Customer_Risk.tmdl`.

## Portfolio measures

### Total Customers
```DAX
COUNTROWS('Customer_Risk')
```
Format: `#,##0`

### Defaulted Customers
```DAX
CALCULATE([Total Customers], 'Customer_Risk'[default payment next month] = 1)
```

### Observed Default Rate
```DAX
DIVIDE([Defaulted Customers], [Total Customers], 0)
```
Format: `0.00%`

### Total Credit Limit
```DAX
SUM('Customer_Risk'[LIMIT_BAL])
```

### Average Credit Limit
```DAX
AVERAGE('Customer_Risk'[LIMIT_BAL])
```

### Average 6M Bill
```DAX
AVERAGE('Customer_Risk'[Avg_Bill_6M])
```

### Average 6M Payment
```DAX
AVERAGE('Customer_Risk'[Avg_Payment_6M])
```

### Average Latest Utilization
```DAX
AVERAGE('Customer_Risk'[Credit_Utilization])
```

> `Credit_Utilization` is the latest-period bill-to-credit-limit ratio (`BILL_AMT1 / LIMIT_BAL`), used as a point-in-time utilization proxy.

### Customers With Delinquency
```DAX
CALCULATE([Total Customers], 'Customer_Risk'[Delinquency_Count] > 0)
```

### Delinquency Rate
```DAX
DIVIDE([Customers With Delinquency], [Total Customers], 0)
```

### Positive-Bill Customers
```DAX
CALCULATE([Total Customers], 'Customer_Risk'[BILL_AMT1] > 0)
```

### Positive-Bill No Payment
```DAX
CALCULATE([Total Customers], 'Customer_Risk'[BILL_AMT1] > 0, 'Customer_Risk'[PAY_AMT1] = 0)
```

### Positive-Bill No-Payment Rate
```DAX
DIVIDE([Positive-Bill No Payment], [Positive-Bill Customers], 0)
```

### Total Payments 6M
```DAX
SUM('Customer_Risk'[PAY_AMT1]) + SUM('Customer_Risk'[PAY_AMT2]) + SUM('Customer_Risk'[PAY_AMT3]) + SUM('Customer_Risk'[PAY_AMT4]) + SUM('Customer_Risk'[PAY_AMT5]) + SUM('Customer_Risk'[PAY_AMT6])
```

### Total Positive Bills 6M
```DAX
SUMX('Customer_Risk', IF('Customer_Risk'[BILL_AMT1] > 0, 'Customer_Risk'[BILL_AMT1], 0) + IF('Customer_Risk'[BILL_AMT2] > 0, 'Customer_Risk'[BILL_AMT2], 0) + IF('Customer_Risk'[BILL_AMT3] > 0, 'Customer_Risk'[BILL_AMT3], 0) + IF('Customer_Risk'[BILL_AMT4] > 0, 'Customer_Risk'[BILL_AMT4], 0) + IF('Customer_Risk'[BILL_AMT5] > 0, 'Customer_Risk'[BILL_AMT5], 0) + IF('Customer_Risk'[BILL_AMT6] > 0, 'Customer_Risk'[BILL_AMT6], 0))
```

### Payment Coverage
```DAX
DIVIDE([Total Payments 6M], [Total Positive Bills 6M], 0)
```
Format: `0.00%`

### Defaulted Credit-Limit Share
```DAX
DIVIDE(
    CALCULATE(
        [Total Credit Limit],
        REMOVEFILTERS('Customer_Risk'[Default_Label]),
        'Customer_Risk'[default payment next month] = 1
    ),
    CALCULATE(
        [Total Credit Limit],
        REMOVEFILTERS(
            'Customer_Risk'[Default_Label],
            'Customer_Risk'[default payment next month]
        )
    ),
    0
)
```

This is the defaulted credit-limit share of the current analytical population while explicitly ignoring the Default Status slicer. Other analytical filters can still define the population.

### Repeated Delay Customers
```DAX
CALCULATE([Total Customers], 'Customer_Risk'[Delinquency_Count] >= 2)
```

### High Exposure Repeated Delay
```DAX
CALCULATE([Total Customers], 'Customer_Risk'[Delinquency_Count] >= 2, 'Customer_Risk'[LIMIT_BAL] >= 100000)
```

### Average Maximum Repayment Status
```DAX
AVERAGE('Customer_Risk'[Max_Delinquency_Code])
```

## Monthly measures

Monthly behavior is modeled through `FactRepayment` and `DimMonth`, not a SWITCH over the wide customer table.

### Monthly Avg Positive Bill
```DAX
CALCULATE(AVERAGE(FactRepayment[BillAmount]), FactRepayment[BillAmount] > 0)
```

### Monthly Avg Payment
```DAX
AVERAGE(FactRepayment[PaymentAmount])
```

### Monthly Total Positive Bills
```DAX
SUMX(FactRepayment, IF(FactRepayment[BillAmount] > 0, FactRepayment[BillAmount], 0))
```

### Monthly Total Payment
```DAX
SUM(FactRepayment[PaymentAmount])
```

### Monthly Payment Coverage
```DAX
DIVIDE([Monthly Total Payment], [Monthly Total Positive Bills], 0)
```
Format: `0.00%`

### Monthly Delay Rate
```DAX
DIVIDE(
    CALCULATE(
        COUNTROWS(FactRepayment),
        FactRepayment[PayStatus] > 0
    ),
    COUNTROWS(FactRepayment),
    0
)
```
Format: `0.00%`
