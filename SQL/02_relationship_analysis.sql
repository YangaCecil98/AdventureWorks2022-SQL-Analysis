/*
===============================================================================
Project:      AdventureWorks2022 SQL Analysis
File:         02_relationship_analysis.sql
Purpose:      Analyse relationships between orders, order lines, and products
Database:     AdventureWorks2022
DBMS:         Microsoft SQL Server
===============================================================================

Core Relationships:

    Sales.SalesOrderHeader
            |
            | 1 : Many
            v
    Sales.SalesOrderDetail
            |
            | Many : 1
            v
    Production.Product

Analytical Grain:

    SalesOrderDetailID -> 1 row = 1 order line
    SalesOrderID     -> 1 row = 1 sales order after aggregation
    ProductID        -> 1 row = 1 product after aggregation

Key Measures:

    Order-line value = OrderQty * UnitPrice
    Order value      = SUM(OrderQty * UnitPrice)

===============================================================================
*/

USE AdventureWorks2022;
GO


/*=============================================================================
1. SALES ORDER → ORDER DETAIL RELATIONSHIP
=============================================================================*/

-- Retrieve sales order and corresponding order-line information.
-- This demonstrates the one-to-many relationship between
-- SalesOrderHeader and SalesOrderDetail.

SELECT
    Detail.ProductID,
    Detail.SalesOrderDetailID,
    Sale.SalesOrderID,
    Sale.OrderDate
FROM Sales.SalesOrderHeader AS Sale
INNER JOIN Sales.SalesOrderDetail AS Detail
    ON Detail.SalesOrderID = Sale.SalesOrderID
ORDER BY
    Sale.SalesOrderID ASC;


/*=============================================================================
2. SALES ORDER → ORDER DETAIL → PRODUCT RELATIONSHIP
=============================================================================*/

-- Extend the previous relationship by joining order details
-- to their corresponding product information.

SELECT TOP 10
    Detail.ProductID,
    Detail.SalesOrderDetailID,
    Sale.SalesOrderID,
    Sale.OrderDate,
    Prod.Name
FROM Sales.SalesOrderHeader AS Sale
INNER JOIN Sales.SalesOrderDetail AS Detail
    ON Detail.SalesOrderID = Sale.SalesOrderID
INNER JOIN Production.Product AS Prod
    ON Prod.ProductID = Detail.ProductID
ORDER BY
    Sale.SalesOrderID ASC;


/*=============================================================================
3. ORDER-LINE VALUE
=============================================================================*/

-- Calculate the monetary value of each individual order line.
--
-- Order-line value is calculated as:
-- OrderQty × UnitPrice

SELECT TOP 10
    Detail.SalesOrderID,
    Detail.SalesOrderDetailID,
    Detail.ProductID,
    Detail.OrderQty,
    Detail.UnitPrice,
    Detail.OrderQty * Detail.UnitPrice AS Order_Line_Value
FROM Sales.SalesOrderDetail AS Detail
ORDER BY
    Detail.SalesOrderID,
    Detail.SalesOrderDetailID;


/*=============================================================================
4. AGGREGATE ORDER-LINE VALUES TO ORDER LEVEL
=============================================================================*/

-- Aggregate individual order-line values to calculate
-- the total value of each sales order.
--
-- GROUP BY SalesOrderID changes the result from:
--     1 row = 1 order line
-- to:
--     1 row = 1 sales order

SELECT TOP 10
    Sale.SalesOrderID,
    SUM(Detail.OrderQty * Detail.UnitPrice) AS Total_Order_Amount
FROM Sales.SalesOrderHeader AS Sale
INNER JOIN Sales.SalesOrderDetail AS Detail
    ON Detail.SalesOrderID = Sale.SalesOrderID
GROUP BY
    Sale.SalesOrderID
ORDER BY
    Sale.SalesOrderID ASC;


/*=============================================================================
5. HIGHEST-VALUE SALES ORDERS
=============================================================================*/

-- Rank sales orders according to their total calculated order value.

SELECT TOP 10
    Sale.SalesOrderID,
    SUM(Detail.OrderQty * Detail.UnitPrice) AS Total_Order_Amount
FROM Sales.SalesOrderHeader AS Sale
INNER JOIN Sales.SalesOrderDetail AS Detail
    ON Detail.SalesOrderID = Sale.SalesOrderID
GROUP BY
    Sale.SalesOrderID
ORDER BY
    Total_Order_Amount DESC;


/*=============================================================================
6. ORDER COMPOSITION OF HIGH-VALUE ORDERS
=============================================================================*/

-- Examine the characteristics of the highest-value orders.
--
-- Measures:
--     Total_Order_Items = number of order-detail records
--     Total_Quantity    = total units ordered
--     Average_Unit_Price = average unit price across order lines
--     Total_Order_Amount = calculated order value

SELECT TOP 50
    Sale.SalesOrderID,
    COUNT(Detail.SalesOrderDetailID) AS Total_Order_Items,
    SUM(Detail.OrderQty) AS Total_Quantity,
    AVG(Detail.UnitPrice) AS Average_Unit_Price,
    SUM(Detail.OrderQty * Detail.UnitPrice) AS Total_Order_Amount
FROM Sales.SalesOrderHeader AS Sale
INNER JOIN Sales.SalesOrderDetail AS Detail
    ON Detail.SalesOrderID = Sale.SalesOrderID
GROUP BY
    Sale.SalesOrderID
ORDER BY
    Total_Order_Amount DESC;


/*=============================================================================
7. PRODUCTS WITHIN THE HIGHEST-VALUE ORDERS
=============================================================================*/

-- Identify the products contributing to the 50 highest-value orders.
--
-- The subquery first identifies the target orders.
-- The outer query then retrieves their individual order lines
-- and associated product information.

SELECT TOP 50
    Detail.SalesOrderID,
    Detail.ProductID,
    Detail.OrderQty,
    Detail.UnitPrice,
    Prod.Name
FROM Sales.SalesOrderDetail AS Detail
INNER JOIN Production.Product AS Prod
    ON Prod.ProductID = Detail.ProductID
WHERE Detail.SalesOrderID IN
(
    SELECT TOP 50
        SalesOrderID
    FROM Sales.SalesOrderDetail
    GROUP BY
        SalesOrderID
    ORDER BY
        SUM(OrderQty * UnitPrice) DESC
)
ORDER BY
    Detail.SalesOrderID,
    Detail.ProductID;


/*=============================================================================
8. TOP PRODUCTS BY SALES VALUE WITHIN THE HIGHEST-VALUE ORDERS
=============================================================================*/

-- Determine which products contributed the most sales value
-- across the 10 highest-value sales orders.

SELECT TOP 10
    Detail.ProductID,
    Prod.Name,
    SUM(Detail.OrderQty) AS Total_Quantity,
    SUM(Detail.UnitPrice * Detail.OrderQty) AS Total_Product_Value
FROM Sales.SalesOrderDetail AS Detail
INNER JOIN Production.Product AS Prod
    ON Prod.ProductID = Detail.ProductID
WHERE Detail.SalesOrderID IN
(
    SELECT TOP 10
        SalesOrderID
    FROM Sales.SalesOrderDetail
    GROUP BY
        SalesOrderID
    ORDER BY
        SUM(OrderQty * UnitPrice) DESC
)
GROUP BY
    Detail.ProductID,
    Prod.Name
ORDER BY
    Total_Product_Value DESC;


/*=============================================================================
9. PRODUCT CONTRIBUTION TO VALUE OF THE HIGHEST-VALUE ORDERS
=============================================================================*/

-- Calculate the percentage contribution of each product
-- to the total value generated within the selected
-- highest-value orders.

SELECT TOP 10
    Detail.ProductID,
    Prod.Name,
    SUM(Detail.OrderQty) AS Total_Quantity,
    SUM(Detail.UnitPrice * Detail.OrderQty) AS Total_Product_Value,

    SUM(Detail.UnitPrice * Detail.OrderQty)
        / SUM(SUM(Detail.UnitPrice * Detail.OrderQty)) OVER () * 100
        AS Product_Contribution_Percentage

FROM Sales.SalesOrderDetail AS Detail

INNER JOIN Production.Product AS Prod
    ON Prod.ProductID = Detail.ProductID

WHERE Detail.SalesOrderID IN
(
    SELECT TOP 10
        SalesOrderID
    FROM Sales.SalesOrderDetail
    GROUP BY
        SalesOrderID
    ORDER BY
        SUM(OrderQty * UnitPrice) DESC
)

GROUP BY
    Detail.ProductID,
    Prod.Name

ORDER BY
    Total_Product_Value DESC;


/*=============================================================================
10. ANALYTICAL OBSERVATIONS
=============================================================================

Key observations established during relationship analysis:

1. SalesOrderHeader and SalesOrderDetail form a one-to-many relationship.
   One sales order can contain multiple order-detail records.

2. SalesOrderDetail acts as the bridge between sales orders and products.

3. Order-line value is calculated using:
       OrderQty × UnitPrice

4. Aggregating order-line values by SalesOrderID changes the analytical
   grain from order line to sales order.

5. High-value orders can result from different combinations of:
       - Number of order lines
       - Total quantity
       - Unit price

6. Quantity alone does not determine order value. Unit price also has
   a material effect on the resulting order value.

7. Within the highest-value orders, products with the highest quantities
   do not necessarily generate the highest sales value.

8. Product contribution is distributed across multiple products rather
   than being dominated by a single product.

===============================================================================
*/

