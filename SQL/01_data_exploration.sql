/*
===============================================================================
Project:      AdventureWorks2022 SQL Analysis
File:         01_data_exploration.sql
Purpose:      Initial exploration and data validation of the core tables
Database:     AdventureWorks2022
DBMS:         Microsoft SQL Server
===============================================================================

Core Tables:
    1. Sales.SalesOrderHeader
    2. Sales.SalesOrderDetail
    3. Production.Product

Table Grain:
    SalesOrderHeader  -> 1 row = 1 sales order
    SalesOrderDetail  -> 1 row = 1 order line
    Production.Product -> 1 row = 1 product

Primary Relationships:
    SalesOrderHeader.SalesOrderID
        -> SalesOrderDetail.SalesOrderID

    Production.Product.ProductID
        -> SalesOrderDetail.ProductID

===============================================================================
*/

USE AdventureWorks2022;
GO


/*=============================================================================
1. DATABASE & DBMS INFORMATION
=============================================================================*/

-- Confirm the SQL Server version currently being used.
SELECT
    @@VERSION AS DBMS_Version;


-- Confirm the active database.
SELECT
    DB_NAME() AS Database_Name;


/*=============================================================================
2. TABLE INVENTORY
=============================================================================*/

-- Identify the core tables used in this project.
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA IN ('Sales', 'Production')
    AND TABLE_NAME IN
    (
        'SalesOrderHeader',
        'SalesOrderDetail',
        'Product'
    )
ORDER BY
    TABLE_SCHEMA,
    TABLE_NAME;


/*=============================================================================
3. ROW COUNTS
=============================================================================*/

-- Determine the number of records in each core table.

SELECT
    COUNT(*) AS SalesOrderHeader_Row_Count
FROM Sales.SalesOrderHeader;


SELECT
    COUNT(*) AS SalesOrderDetail_Row_Count
FROM Sales.SalesOrderDetail;


SELECT
    COUNT(*) AS Product_Row_Count
FROM Production.Product;


/*=============================================================================
4. INITIAL DATA INSPECTION
=============================================================================*/

-- Inspect sample records from SalesOrderHeader.
SELECT TOP 10 *
FROM Sales.SalesOrderHeader
ORDER BY SalesOrderID;


-- Inspect sample records from SalesOrderDetail.
SELECT TOP 10 *
FROM Sales.SalesOrderDetail
ORDER BY
    SalesOrderID,
    SalesOrderDetailID;


-- Inspect sample records from Product.
SELECT TOP 10 *
FROM Production.Product
ORDER BY ProductID;


/*=============================================================================
5. PRIMARY KEY UNIQUENESS CHECKS
=============================================================================*/

-- Check for duplicate SalesOrderID values.
-- Expected result: no rows.

SELECT
    SalesOrderID,
    COUNT(SalesOrderID) AS Order_IDs
FROM Sales.SalesOrderHeader
GROUP BY SalesOrderID
HAVING COUNT(SalesOrderID) > 1
ORDER BY Order_IDs;


-- Check for duplicate SalesOrderDetailID values.
-- Expected result: no rows.

SELECT
    SalesOrderDetailID,
    COUNT(SalesOrderDetailID) AS Order_Detail_IDs
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderDetailID
HAVING COUNT(SalesOrderDetailID) > 1
ORDER BY Order_Detail_IDs;


-- Check for duplicate ProductID values.
-- Expected result: no rows.

SELECT
    ProductID,
    COUNT(ProductID) AS Product_IDs
FROM Production.Product
GROUP BY ProductID
HAVING COUNT(ProductID) > 1
ORDER BY Product_IDs;


/*=============================================================================
6. FOREIGN KEY INTEGRITY CHECKS
=============================================================================*/

-- Check whether every SalesOrderID in SalesOrderDetail
-- has a corresponding record in SalesOrderHeader.
-- Expected result: no rows.

SELECT
    Detail.SalesOrderID
FROM Sales.SalesOrderDetail AS Detail
LEFT JOIN Sales.SalesOrderHeader AS Sale
    ON Sale.SalesOrderID = Detail.SalesOrderID
WHERE Sale.SalesOrderID IS NULL;


-- Check whether every ProductID in SalesOrderDetail
-- has a corresponding record in Production.Product.
-- Expected result: no rows.

SELECT
    Detail.ProductID
FROM Sales.SalesOrderDetail AS Detail
LEFT JOIN Production.Product AS Prod
    ON Prod.ProductID = Detail.ProductID
WHERE Prod.ProductID IS NULL;


/*=============================================================================
7. RELEVANT NULL CHECK
=============================================================================*/

-- Check for NULL CustomerID values in SalesOrderHeader.

SELECT
    SUM(
        CASE
            WHEN CustomerID IS NULL THEN 1
            ELSE 0
        END
    ) AS Null_Customer
FROM Sales.SalesOrderHeader;


/*=============================================================================
8. INITIAL STRUCTURAL OBSERVATIONS
=============================================================================

Key observations established during exploration:

- SalesOrderHeader contains one record per sales order.
- SalesOrderDetail contains individual order-line records.
- A single SalesOrderID can therefore appear multiple times in
  SalesOrderDetail without representing duplicate orders.
- ProductID links individual order lines to product information.
- Primary key uniqueness checks identified no duplicate key values.
- Foreign key checks identified no orphaned SalesOrderID or ProductID references.
- CustomerID completeness was checked at the order-header level.

The relationships established here form the foundation for the analytical
queries developed in the subsequent SQL files.

===============================================================================
*/
```
