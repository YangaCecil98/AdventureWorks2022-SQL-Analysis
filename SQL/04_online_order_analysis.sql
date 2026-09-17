/*
===============================================================================
Project:      AdventureWorks2022 SQL Analysis
File:         04_online_order_analysis.sql
Purpose:      Compare online and non-online orders using order value,
              order composition, and distributional statistics
Database:     AdventureWorks2022
DBMS:         Microsoft SQL Server
===============================================================================

Analytical Focus:

    1. Compare average order value by OnlineOrderFlag
    2. Compare order composition between online and non-online orders
    3. Compare order-level and line-level unit price measures
    4. Investigate whether differences in average order value are
       reflected in the underlying distributions
    5. Calculate minimum, maximum, median, quartiles, and IQR

OnlineOrderFlag:

    0 = Non-online order
    1 = Online order

Important Analytical Distinction:

    The analysis first creates one row per sales order.

    Order-detail grain
        1 row = 1 order line
                ↓
        SUM / AVG by SalesOrderID
                ↓
    Order grain
        1 row = 1 sales order
                ↓
        GROUP BY OnlineOrderFlag
                ↓
    Order-type grain
        1 row = Online / Non-online

===============================================================================
*/

USE AdventureWorks2022;
GO

/*=============================================================================
1. AVERAGE ORDER VALUE BY ONLINE ORDER STATUS
=============================================================================*/

-- First calculate the total value of each sales order.
-- The outer query then compares the completed orders by OnlineOrderFlag.

WITH OrderValues AS
(
    SELECT
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag,
        SUM(Detail.OrderQty * Detail.UnitPrice) AS Total_Order_Amount
    FROM Sales.SalesOrderHeader AS Sale
    INNER JOIN Sales.SalesOrderDetail AS Detail
        ON Detail.SalesOrderID = Sale.SalesOrderID
    GROUP BY
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag
)

SELECT
    OnlineOrderFlag,
    COUNT(SalesOrderID) AS Number_Of_Orders,
    AVG(Total_Order_Amount) AS Average_Order_Value
FROM OrderValues
GROUP BY
    OnlineOrderFlag
ORDER BY
    OnlineOrderFlag;


/*=============================================================================
2. ORDER COMPOSITION BY ONLINE ORDER STATUS
=============================================================================*/

-- Compare the characteristics of individual orders by OnlineOrderFlag.
--
-- Each row in the CTE represents one completed sales order.
-- The outer query then calculates averages across those orders.

WITH OrderComposition AS
(
    SELECT
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag,
        COUNT(Detail.SalesOrderDetailID) AS Number_Of_Order_Items,
        SUM(Detail.OrderQty) AS Total_Quantity,
        AVG(Detail.UnitPrice) AS Average_Unit_Price,
        SUM(Detail.OrderQty * Detail.UnitPrice) AS Total_Order_Amount
    FROM Sales.SalesOrderHeader AS Sale
    INNER JOIN Sales.SalesOrderDetail AS Detail
        ON Detail.SalesOrderID = Sale.SalesOrderID
    GROUP BY
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag
)

SELECT
    OnlineOrderFlag,
    AVG(Average_Unit_Price) AS Average_Order_Level_Unit_Price,
    AVG(Number_Of_Order_Items) AS Average_Number_Of_Items,
    AVG(Total_Quantity) AS Average_Quantity,
    AVG(Total_Order_Amount) AS Average_Order_Value
FROM OrderComposition
GROUP BY
    OnlineOrderFlag
ORDER BY
    OnlineOrderFlag;


/*=============================================================================
3. LINE-WEIGHTED AVERAGE UNIT PRICE
=============================================================================*/

-- Calculate the average UnitPrice at order-line grain.
--
-- Unlike Query 2, each order line receives equal weight.
-- This produces a line-weighted average rather than an
-- order-weighted average.

SELECT
    Sale.OnlineOrderFlag,
    AVG(Detail.UnitPrice)
        OVER(PARTITION BY Sale.OnlineOrderFlag) AS Line_Weighted_Average_Unit_Price
FROM Sales.SalesOrderHeader AS Sale
INNER JOIN Sales.SalesOrderDetail AS Detail
    ON Detail.SalesOrderID = Sale.SalesOrderID;


/*=============================================================================
4. MINIMUM, MAXIMUM, AND AVERAGE ORDER VALUE
=============================================================================*/

-- Examine the range of order values before calculating
-- median and percentile statistics.

WITH OrderValues AS
(
    SELECT
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag,
        SUM(Detail.OrderQty * Detail.UnitPrice) AS Total_Order_Value
    FROM Sales.SalesOrderHeader AS Sale
    INNER JOIN Sales.SalesOrderDetail AS Detail
        ON Detail.SalesOrderID = Sale.SalesOrderID
    GROUP BY
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag
)

SELECT
    OnlineOrderFlag,
    COUNT(SalesOrderID) AS Number_Of_Orders,
    MIN(Total_Order_Value) AS Min_Order_Value,
    MAX(Total_Order_Value) AS Max_Order_Value,
    AVG(Total_Order_Value) AS Average_Order_Value
FROM OrderValues
GROUP BY
    OnlineOrderFlag
ORDER BY
    OnlineOrderFlag;


/*=============================================================================
5. MEDIAN ORDER VALUE
=============================================================================*/

-- Calculate the median order value for each order type.
--
-- PERCENTILE_CONT(0.5) represents the 50th percentile.
--
-- The window function initially returns the median on every row
-- within each OnlineOrderFlag partition.
--
-- The final GROUP BY collapses those repeated values into one
-- result per order type.

WITH OrderValues AS
(
    SELECT
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag,
        SUM(Detail.OrderQty * Detail.UnitPrice) AS Total_Order_Value
    FROM Sales.SalesOrderHeader AS Sale
    INNER JOIN Sales.SalesOrderDetail AS Detail
        ON Detail.SalesOrderID = Sale.SalesOrderID
    GROUP BY
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag
),

MedianValues AS
(
    SELECT
        OnlineOrderFlag,
        Total_Order_Value,
        PERCENTILE_CONT(0.5)
            WITHIN GROUP(ORDER BY Total_Order_Value)
            OVER(PARTITION BY OnlineOrderFlag) AS Median_Order_Value
    FROM OrderValues
)

SELECT
    OnlineOrderFlag,
    MIN(Total_Order_Value) AS Min_Order_Value,
    MAX(Total_Order_Value) AS Max_Order_Value,
    AVG(Total_Order_Value) AS Average_Order_Value,
    Median_Order_Value
FROM MedianValues
GROUP BY
    OnlineOrderFlag,
    Median_Order_Value
ORDER BY
    OnlineOrderFlag;


/*=============================================================================
6. FIRST QUARTILE (Q1)
=============================================================================*/

-- Calculate the 25th percentile of order value for each order type.

WITH OrderValues AS
(
    SELECT
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag,
        SUM(Detail.OrderQty * Detail.UnitPrice) AS Total_Order_Value
    FROM Sales.SalesOrderHeader AS Sale
    INNER JOIN Sales.SalesOrderDetail AS Detail
        ON Detail.SalesOrderID = Sale.SalesOrderID
    GROUP BY
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag
),

FirstQuartile AS
(
    SELECT
        OnlineOrderFlag,
        Total_Order_Value,
        PERCENTILE_CONT(0.25)
            WITHIN GROUP(ORDER BY Total_Order_Value)
            OVER(PARTITION BY OnlineOrderFlag) AS Q1_Order_Value
    FROM OrderValues
)

SELECT
    OnlineOrderFlag,
    MIN(Total_Order_Value) AS Min_Order_Value,
    MAX(Total_Order_Value) AS Max_Order_Value,
    AVG(Total_Order_Value) AS Average_Order_Value,
    Q1_Order_Value
FROM FirstQuartile
GROUP BY
    OnlineOrderFlag,
    Q1_Order_Value
ORDER BY
    OnlineOrderFlag;


/*=============================================================================
7. THIRD QUARTILE (Q3)
=============================================================================*/

-- Calculate the 75th percentile of order value for each order type.

WITH OrderValues AS
(
    SELECT
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag,
        SUM(Detail.OrderQty * Detail.UnitPrice) AS Total_Order_Value
    FROM Sales.SalesOrderHeader AS Sale
    INNER JOIN Sales.SalesOrderDetail AS Detail
        ON Detail.SalesOrderID = Sale.SalesOrderID
    GROUP BY
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag
),

ThirdQuartile AS
(
    SELECT
        OnlineOrderFlag,
        Total_Order_Value,
        PERCENTILE_CONT(0.75)
            WITHIN GROUP(ORDER BY Total_Order_Value)
            OVER(PARTITION BY OnlineOrderFlag) AS Q3_Order_Value
    FROM OrderValues
)

SELECT
    OnlineOrderFlag,
    MIN(Total_Order_Value) AS Min_Order_Value,
    MAX(Total_Order_Value) AS Max_Order_Value,
    AVG(Total_Order_Value) AS Average_Order_Value,
    Q3_Order_Value
FROM ThirdQuartile
GROUP BY
    OnlineOrderFlag,
    Q3_Order_Value
ORDER BY
    OnlineOrderFlag;


/*=============================================================================
8. INTERQUARTILE RANGE (IQR)
=============================================================================*/

-- Calculate Q1, median, and Q3 in one query and derive the
-- Interquartile Range.
--
-- IQR = Q3 - Q1
--
-- The IQR represents the spread of the middle 50% of orders.

WITH OrderValues AS
(
    SELECT
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag,
        SUM(Detail.OrderQty * Detail.UnitPrice) AS Total_Order_Value
    FROM Sales.SalesOrderHeader AS Sale
    INNER JOIN Sales.SalesOrderDetail AS Detail
        ON Detail.SalesOrderID = Sale.SalesOrderID
    GROUP BY
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag
),

DistributionStats AS
(
    SELECT
        OnlineOrderFlag,
        Total_Order_Value,

        PERCENTILE_CONT(0.25)
            WITHIN GROUP(ORDER BY Total_Order_Value)
            OVER(PARTITION BY OnlineOrderFlag) AS Q1_Order_Value,

        PERCENTILE_CONT(0.50)
            WITHIN GROUP(ORDER BY Total_Order_Value)
            OVER(PARTITION BY OnlineOrderFlag) AS Median_Order_Value,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP(ORDER BY Total_Order_Value)
            OVER(PARTITION BY OnlineOrderFlag) AS Q3_Order_Value

    FROM OrderValues
)

SELECT
    OnlineOrderFlag,
    MIN(Total_Order_Value) AS Min_Order_Value,
    MAX(Total_Order_Value) AS Max_Order_Value,
    AVG(Total_Order_Value) AS Average_Order_Value,
    MIN(Q1_Order_Value) AS Q1_Order_Value,
    MIN(Median_Order_Value) AS Median_Order_Value,
    MIN(Q3_Order_Value) AS Q3_Order_Value,
    MIN(Q3_Order_Value) - MIN(Q1_Order_Value) AS IQR
FROM DistributionStats
GROUP BY
    OnlineOrderFlag
ORDER BY
    OnlineOrderFlag;


/*=============================================================================
9. FINAL DISTRIBUTION SUMMARY
=============================================================================*/

-- Produce a concise five-number summary plus the mean and IQR.
--
-- This provides the statistical foundation for comparing the
-- distributions of online and non-online order values.

WITH OrderValues AS
(
    SELECT
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag,
        SUM(Detail.OrderQty * Detail.UnitPrice) AS Total_Order_Value
    FROM Sales.SalesOrderHeader AS Sale
    INNER JOIN Sales.SalesOrderDetail AS Detail
        ON Detail.SalesOrderID = Sale.SalesOrderID
    GROUP BY
        Sale.SalesOrderID,
        Sale.OnlineOrderFlag
),

DistributionStats AS
(
    SELECT
        OnlineOrderFlag,
        Total_Order_Value,

        PERCENTILE_CONT(0.25)
            WITHIN GROUP(ORDER BY Total_Order_Value)
            OVER(PARTITION BY OnlineOrderFlag) AS Q1,

        PERCENTILE_CONT(0.50)
            WITHIN GROUP(ORDER BY Total_Order_Value)
            OVER(PARTITION BY OnlineOrderFlag) AS Median,

        PERCENTILE_CONT(0.75)
            WITHIN GROUP(ORDER BY Total_Order_Value)
            OVER(PARTITION BY OnlineOrderFlag) AS Q3

    FROM OrderValues
)

SELECT
    OnlineOrderFlag,
    MIN(Total_Order_Value) AS Min_Order_Value,
    MIN(Q1) AS Q1,
    MIN(Median) AS Median,
    AVG(Total_Order_Value) AS Mean,
    MIN(Q3) AS Q3,
    MAX(Total_Order_Value) AS Max_Order_Value,
    MIN(Q3) - MIN(Q1) AS IQR
FROM DistributionStats
GROUP BY
    OnlineOrderFlag
ORDER BY
    OnlineOrderFlag;


/*=============================================================================
10. ANALYTICAL OBSERVATIONS
=============================================================================

Online vs Non-Online Order Analysis established the following:

1. Non-online orders have a substantially higher average order value
   than online orders in this dataset.

2. Non-online orders contain considerably more order lines and units
   per order.

3. The average order-level unit price for non-online orders is lower
   than that of online orders.

4. This indicates that the difference in average order value is strongly
   associated with order volume and order composition rather than simply
   higher unit prices.

5. Order-level and line-level averages can produce different results
   because they apply different weighting schemes.

   Order-weighted average:
       Each order receives equal weight.

   Line-weighted average:
       Each order line receives equal weight.

6. Both online and non-online order-value distributions are right-skewed,
   with the mean exceeding the median.

7. The non-online distribution has a substantially wider IQR, indicating
   greater variation in the middle 50% of order values.

8. The non-online upper tail extends considerably further beyond its
   third quartile than the online distribution.

9. Minimum and maximum values alone are insufficient to determine whether
   unusually large orders are driving the mean. Median, quartile, and
   IQR analysis provides additional distributional context.

10. These observations describe associations within the dataset and do
    not establish causal relationships between order type and order value.

===============================================================================
*/

