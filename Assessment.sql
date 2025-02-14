-- Creating the 'salesdata' table with appropriate data types and constraints.
-- TransactionID is set as PRIMARY KEY with AUTO_INCREMENT.
CREATE TABLE `salesdata` (
   `TransactionID` int NOT NULL AUTO_INCREMENT,
   `CustomerID` int DEFAULT NULL,
   `TransactionDate` date DEFAULT NULL,
   `TransactionAmount` decimal(12,2) DEFAULT NULL,
   `PaymentMethod` varchar(50) DEFAULT NULL,
   `Quantity` int DEFAULT NULL,
   `DiscountPercent` decimal(5,2) DEFAULT NULL,
   `City` varchar(100) DEFAULT NULL,
   `StoreType` varchar(50) DEFAULT NULL,
   `CustomerAge` int DEFAULT NULL,
   `CustomerGender` varchar(20) DEFAULT NULL,
   `LoyaltyPoints` int DEFAULT NULL,
   `ProductName` varchar(100) DEFAULT NULL,
   `Region` varchar(50) DEFAULT NULL,
   `Returned` varchar(10) DEFAULT NULL,
   `FeedbackScore` tinyint DEFAULT NULL,
   `ShippingCost` decimal(10,2) DEFAULT NULL,
   `DeliveryTimeDays` int DEFAULT NULL,
   `IsPromotional` varchar(10) DEFAULT NULL,
   PRIMARY KEY (`TransactionID`)
 ) ;

-- Loading data from a CSV file into 'salesdata' table.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/assessment_dataset.csv'
INTO TABLE salesdata
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(TransactionID, @CustomerID, @TransactionDate, TransactionAmount, 
PaymentMethod, Quantity, DiscountPercent, City, StoreType, @CustomerAge, 
CustomerGender, LoyaltyPoints, ProductName, Region, Returned, FeedbackScore, 
ShippingCost, DeliveryTimeDays, IsPromotional)
SET CustomerID = NULLIF(@CustomerID, ''),
    TransactionDate = NULLIF(@TransactionDate, ''),
    CustomerAge = NULLIF(@CustomerAge, '');

-- Selecting all records from 'salesdata' (part of 'incubyte' schema).
SELECT * FROM incubyte.salesdata;

-- Checking for NULL or empty values across all columns in the 'salesdata' table.
SELECT * 
FROM salesdata
WHERE 
    TransactionID IS NULL
    OR CustomerID IS NULL OR CustomerID = ''
    OR TransactionDate IS NULL 
    OR TransactionAmount IS NULL OR TransactionAmount = ''
    OR PaymentMethod IS NULL OR PaymentMethod = ''
    OR Quantity IS NULL OR Quantity = ''
    OR DiscountPercent IS NULL OR DiscountPercent = ''
    OR City IS NULL OR City = ''
    OR StoreType IS NULL OR StoreType = ''
    OR CustomerAge IS NULL OR CustomerAge = ''
    OR CustomerGender IS NULL OR CustomerGender = ''
    OR LoyaltyPoints IS NULL OR LoyaltyPoints = ''
    OR ProductName IS NULL OR ProductName = ''
    OR Region IS NULL OR Region = ''
    OR Returned IS NULL OR Returned = ''
    OR FeedbackScore IS NULL OR FeedbackScore = ''
    OR ShippingCost IS NULL OR ShippingCost = ''
    OR DeliveryTimeDays IS NULL OR DeliveryTimeDays = ''
    OR IsPromotional IS NULL OR IsPromotional = '';

-- Getting a summary of missing values (NULL or empty) for each column.
SELECT 
    SUM(CASE WHEN TransactionID IS NULL OR TransactionID = '' THEN 1 ELSE 0 END) AS TransactionID_missing,
    SUM(CASE WHEN CustomerID IS NULL OR CustomerID = '' THEN 1 ELSE 0 END) AS CustomerID_missing,
    SUM(CASE WHEN TransactionDate IS NULL  THEN 1 ELSE 0 END) AS TransactionDate_missing,
    SUM(CASE WHEN TransactionAmount IS NULL OR TransactionAmount = '' THEN 1 ELSE 0 END) AS TransactionAmount_missing,
    SUM(CASE WHEN PaymentMethod IS NULL OR PaymentMethod = '' THEN 1 ELSE 0 END) AS PaymentMethod_missing,
    SUM(CASE WHEN Quantity IS NULL OR Quantity = '' THEN 1 ELSE 0 END) AS Quantity_missing,
    SUM(CASE WHEN DiscountPercent IS NULL OR DiscountPercent = '' THEN 1 ELSE 0 END) AS DiscountPercent_missing,
    SUM(CASE WHEN City IS NULL OR City = '' THEN 1 ELSE 0 END) AS City_missing,
    SUM(CASE WHEN StoreType IS NULL OR StoreType = '' THEN 1 ELSE 0 END) AS StoreType_missing,
    SUM(CASE WHEN CustomerAge IS NULL OR CustomerAge = '' THEN 1 ELSE 0 END) AS CustomerAge_missing,
    SUM(CASE WHEN CustomerGender IS NULL OR CustomerGender = '' THEN 1 ELSE 0 END) AS CustomerGender_missing,
    SUM(CASE WHEN LoyaltyPoints IS NULL OR LoyaltyPoints = '' THEN 1 ELSE 0 END) AS LoyaltyPoints_missing,
    SUM(CASE WHEN ProductName IS NULL OR ProductName = '' THEN 1 ELSE 0 END) AS ProductName_missing,
    SUM(CASE WHEN Region IS NULL OR Region = '' THEN 1 ELSE 0 END) AS Region_missing,
    SUM(CASE WHEN Returned IS NULL OR Returned = '' THEN 1 ELSE 0 END) AS Returned_missing,
    SUM(CASE WHEN FeedbackScore IS NULL OR FeedbackScore = '' THEN 1 ELSE 0 END) AS FeedbackScore_missing,
    SUM(CASE WHEN ShippingCost IS NULL OR ShippingCost = '' THEN 1 ELSE 0 END) AS ShippingCost_missing,
    SUM(CASE WHEN DeliveryTimeDays IS NULL OR DeliveryTimeDays = '' THEN 1 ELSE 0 END) AS DeliveryTimeDays_missing,
    SUM(CASE WHEN IsPromotional IS NULL OR IsPromotional = '' THEN 1 ELSE 0 END) AS IsPromotional_missing
FROM salesdata;

-- Forward filling NULL values in TransactionDate with the previous non-null date (imputing missing dates).
SET @prev_date = NULL;

UPDATE salesdata
SET TransactionDate = (
    SELECT @prev_date := COALESCE(TransactionDate, @prev_date)
)
ORDER BY TransactionID;


-- Identifying duplicate records based on all columns.
SELECT *, COUNT(*) AS count
FROM salesdata
GROUP BY TransactionID, CustomerID, TransactionDate, TransactionAmount, 
PaymentMethod, Quantity, DiscountPercent, City, StoreType, CustomerAge, 
CustomerGender, LoyaltyPoints, ProductName, Region, Returned, FeedbackScore, 
ShippingCost, DeliveryTimeDays, IsPromotional
HAVING COUNT(*) > 1;

-- Counting duplicate CustomerIDs and sorting in descending order by count.
SELECT CustomerID, COUNT(*) AS count
FROM salesdata
GROUP BY CustomerID
HAVING COUNT(*) > 1
ORDER BY count DESC;

-- Replacing empty strings with 'Unknown' for categorical columns (PaymentMethod, StoreType, Region, CustomerGender, ProductName).
UPDATE salesdata
SET PaymentMethod = 'Unknown'
WHERE PaymentMethod="";

UPDATE salesdata
SET StoreType = 'Unknown'
WHERE StoreType="";

UPDATE salesdata
SET Region = 'Unknown'
WHERE Region="";

UPDATE salesdata
SET CustomerGender = 'Unknown'
WHERE CustomerGender="";

UPDATE salesdata
SET ProductName = 'Unknown'
WHERE ProductName="";

-- Replacing NULL values in CustomerAge with the average age.
UPDATE salesdata
SET CustomerAge = (
    SELECT mean_age
    FROM (SELECT ROUND(AVG(CustomerAge)) AS mean_age 
          FROM salesdata 
          WHERE CustomerAge IS NOT NULL) AS temp_table
)
WHERE CustomerAge IS NULL;

-- Getting CustomerID-wise transaction counts.
SELECT CustomerID, COUNT(*)
FROM salesdata
GROUP BY CustomerID;

-- Getting CustomerID-wise transaction counts excluding CustomerID=0.
SELECT CustomerID, COUNT(*)
FROM salesdata
WHERE CustomerID != 0
GROUP BY CustomerID;

-- Getting the minimum and maximum values of TransactionAmount from salesdata.
SELECT
    'TransactionAmount',
    MIN(TransactionAmount) AS min,
    MAX(TransactionAmount) AS max
FROM salesdata;

-- Counting negative TransactionAmount values (to check invalid transactions).
SELECT COUNT(*) AS NegativeTransactionCount
FROM salesdata
WHERE TransactionAmount < 0;

-- Creating a view 'positive_salesdata' containing only records with positive TransactionAmount.
CREATE VIEW positive_salesdata AS
SELECT *
FROM salesdata
WHERE TransactionAmount > 0;

-- Getting descriptive statistics for numerical columns from 'positive_salesdata'.
SELECT
    'TransactionAmount' AS column_name,
    COUNT(TransactionAmount) AS count,
    MIN(TransactionAmount) AS min,
    MAX(TransactionAmount) AS max,
    AVG(TransactionAmount) AS mean,
    STD(TransactionAmount) AS std
FROM positive_salesdata

UNION ALL

SELECT
    'Quantity', COUNT(Quantity), MIN(Quantity), MAX(Quantity), AVG(Quantity), STD(Quantity)
FROM positive_salesdata

UNION ALL

SELECT
    'DiscountPercent', COUNT(DiscountPercent), MIN(DiscountPercent), MAX(DiscountPercent), AVG(DiscountPercent), STD(DiscountPercent)
FROM positive_salesdata

UNION ALL

SELECT
    'CustomerAge', COUNT(CustomerAge), MIN(CustomerAge), MAX(CustomerAge), AVG(CustomerAge), STD(CustomerAge)
FROM positive_salesdata

UNION ALL

SELECT
    'LoyaltyPoints', COUNT(LoyaltyPoints), MIN(LoyaltyPoints), MAX(LoyaltyPoints), AVG(LoyaltyPoints), STD(LoyaltyPoints)
FROM positive_salesdata

UNION ALL

SELECT
    'FeedbackScore', COUNT(FeedbackScore), MIN(FeedbackScore), MAX(FeedbackScore), AVG(FeedbackScore), STD(FeedbackScore)
FROM positive_salesdata

UNION ALL

SELECT
    'ShippingCost', COUNT(ShippingCost), MIN(ShippingCost), MAX(ShippingCost), AVG(ShippingCost), STD(ShippingCost)
FROM positive_salesdata

UNION ALL

SELECT
    'DeliveryTimeDays', COUNT(DeliveryTimeDays), MIN(DeliveryTimeDays), MAX(DeliveryTimeDays), AVG(DeliveryTimeDays), STD(DeliveryTimeDays)
FROM positive_salesdata;

-- Counting unique values for each categorical column from 'positive_salesdata'.
SELECT PaymentMethod, COUNT(*) FROM positive_salesdata GROUP BY PaymentMethod;
SELECT City, COUNT(*) FROM positive_salesdata GROUP BY City;
SELECT StoreType, COUNT(*) FROM positive_salesdata GROUP BY StoreType;
SELECT CustomerGender, COUNT(*) FROM positive_salesdata GROUP BY CustomerGender;
SELECT ProductName, COUNT(*) FROM positive_salesdata GROUP BY ProductName;
SELECT Region, COUNT(*) FROM positive_salesdata GROUP BY Region;
SELECT Returned, COUNT(*) FROM positive_salesdata GROUP BY Returned;
SELECT IsPromotional, COUNT(*) FROM positive_salesdata GROUP BY IsPromotional;

-- Getting the minimum and maximum TransactionDate from 'positive_salesdata'.
SELECT MIN(TransactionDate) AS min_date, MAX(TransactionDate) AS max_date FROM positive_salesdata;

-- Calculate total sales for each year and month
SELECT YEAR(TransactionDate) AS year, MONTHNAME(TransactionDate) AS month, SUM(TransactionAmount) AS total_sales
FROM positive_salesdata
GROUP BY year, month
ORDER BY total_sales DESC;

-- Calculate total sales for each city
SELECT 
    City, 
    SUM(TransactionAmount) AS total_sales
FROM positive_salesdata
GROUP BY City
ORDER BY total_sales DESC;

-- Calculate total sales for each product
SELECT 
    ProductName, 
    SUM(TransactionAmount) AS total_sales
FROM positive_salesdata
GROUP BY ProductName
ORDER BY total_sales DESC;

-- Calculate total sales and the number of transactions for each store type
SELECT 
    StoreType, 
    SUM(TransactionAmount) AS total_sales,
    COUNT(*) AS transactions
FROM positive_salesdata
GROUP BY StoreType
ORDER BY total_sales DESC;

-- Calculate total sales and the number of transactions for each payment method
SELECT 
    PaymentMethod, 
    SUM(TransactionAmount) AS total_sales,
    COUNT(*) AS transaction_count
FROM positive_salesdata
GROUP BY PaymentMethod
ORDER BY total_sales DESC;

-- Categorize discount ranges and calculate total sales and transactions
SELECT 
    CASE 
        WHEN DiscountPercent = 0 THEN 'No Discount'
        WHEN DiscountPercent > 0 AND DiscountPercent <= 10 THEN '0-10%'
        WHEN DiscountPercent > 10 AND DiscountPercent <= 20 THEN '10-20%'
        ELSE '>20%'
    END AS discount_range,
    SUM(TransactionAmount) AS total_sales,
    COUNT(*) AS transactions
FROM positive_salesdata
GROUP BY discount_range
ORDER BY total_sales DESC;

-- Categorize customers by age group and calculate total sales and transactions
SELECT 
    CASE 
        WHEN CustomerAge < 18 THEN 'Under 18'
        WHEN CustomerAge BETWEEN 18 AND 25 THEN '18-25'
        WHEN CustomerAge BETWEEN 26 AND 35 THEN '26-35'
        WHEN CustomerAge BETWEEN 36 AND 50 THEN '36-50'
        ELSE 'Above 50'
    END AS age_group,
    SUM(TransactionAmount) AS total_sales,
    COUNT(*) AS transaction_count
FROM positive_salesdata
GROUP BY age_group
ORDER BY total_sales DESC;

-- Calculate total sales and transactions based on whether an item was returned
SELECT 
    Returned, 
    SUM(TransactionAmount) AS total_sales,
    COUNT(*) AS transactions
FROM positive_salesdata
GROUP BY Returned;

-- Calculate total sales for each year and quarter
SELECT 
    YEAR(TransactionDate) AS year,
    QUARTER(TransactionDate) AS quarter,
    SUM(TransactionAmount) AS total_sales
FROM positive_salesdata
GROUP BY year, quarter
ORDER BY year, quarter;

-- Calculate month-over-month sales growth
SELECT 
    YEAR(TransactionDate) AS year,
    MONTH(TransactionDate) AS month,
    SUM(TransactionAmount) AS total_sales,
    LAG(SUM(TransactionAmount)) OVER (ORDER BY YEAR(TransactionDate), MONTH(TransactionDate)) AS previous_month_sales,
    ROUND(((SUM(TransactionAmount) - LAG(SUM(TransactionAmount)) OVER (ORDER BY YEAR(TransactionDate), MONTH(TransactionDate))) / LAG(SUM(TransactionAmount)) OVER (ORDER BY YEAR(TransactionDate), MONTH(TransactionDate))) * 100, 2) AS month_over_month_growth
FROM positive_salesdata
GROUP BY year, month
ORDER BY year, month;

-- Calculate total sales and the number of transactions for each region
SELECT 
    Region, 
    SUM(TransactionAmount) AS total_sales,
    COUNT(*) AS transactions
FROM positive_salesdata
GROUP BY Region
ORDER BY total_sales DESC;

-- Calculate the average transaction value and the number of transactions for each feedback score
SELECT 
    FeedbackScore,
    AVG(TransactionAmount) AS avg_transaction_value,
    COUNT(*) AS transactions
FROM positive_salesdata
GROUP BY FeedbackScore
ORDER BY FeedbackScore;


-- Exporting positive_salesdata with headers to CSV file in the specified path.
(SELECT 'TransactionID', 'CustomerID', 'TransactionDate', 'TransactionAmount', 'PaymentMethod', 'Quantity', 'DiscountPercent', 'City', 'StoreType', 'CustomerAge', 'CustomerGender', 'LoyaltyPoints', 'ProductName', 'Region', 'Returned', 'FeedbackScore', 'ShippingCost', 'DeliveryTimeDays', 'IsPromotional')
UNION ALL
SELECT * FROM positive_salesdata
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/cleaned_salesdata.csv'
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n';
