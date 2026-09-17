# AdventureWorks2022 SQL Analysis

## Project Overview

This project explores the AdventureWorks2022 database using Microsoft SQL Server to investigate sales orders, order details, products, order value, product contribution, and differences between online and non-online orders.

The project focuses on developing practical SQL analysis skills while following a structured analytical workflow — from understanding table relationships and validating data integrity to transforming data to the appropriate grain and extracting business-relevant insights.

The analysis makes use of SQL Server techniques including:

* Table and data exploration
* Primary key and foreign key validation
* INNER JOIN and LEFT JOIN
* Aggregations and GROUP BY
* Subqueries
* Common Table Expressions (CTEs)
* Window functions
* Percentiles and descriptive statistics
* Order-level and product-level analysis

---

## Objectives

The primary objectives of this project are to:

1. Understand the structure and relationships between key AdventureWorks tables.
2. Validate the integrity of the selected data.
3. Analyse sales orders at both order-line and order level.
4. Identify high-value sales orders and examine their composition.
5. Investigate which products contribute most to high-value orders.
6. Compare online and non-online orders using order value and order composition.
7. Examine the distribution of order values using descriptive statistics and percentiles.
8. Translate SQL results into meaningful analytical observations.

---

## Dataset

The project uses the **AdventureWorks2022** sample database.

Three core tables were selected for the main analysis:

| Table                    | Description                     | Approx. Rows |
| ------------------------ | ------------------------------- | -----------: |
| `Sales.SalesOrderHeader` | Sales order-level information   |       31,465 |
| `Sales.SalesOrderDetail` | Individual products/order lines |      121,317 |
| `Production.Product`     | Product information             |          504 |

### Table Grain

Understanding the grain of each table is central to the analysis.

* **SalesOrderHeader** — one row represents one sales order.
* **SalesOrderDetail** — one row represents one product/order line within a sales order.
* **Production.Product** — one row represents one product.

The primary relationship is:

`SalesOrderHeader` → `SalesOrderDetail` → `Production.Product`

A single sales order can contain multiple order-detail records, while each order-detail record references a product.

---

## Analytical Approach

The analysis follows a progressive workflow.

### 1. Data Exploration

The project begins by examining the selected tables, row counts, columns, and sample records to establish an understanding of the available data.

### 2. Data Validation

Basic integrity checks were performed to investigate:

* Duplicate primary keys
* Orphaned foreign-key references
* Relevant NULL values
* Relationships between the selected tables

### 3. Relationship Analysis

The tables were joined to understand how order-level, line-level, and product-level information can be analysed together.

This stage also established the distinction between:

* **Order-line value** — `OrderQty × UnitPrice`
* **Order value** — the sum of all order-line values belonging to an order

### 4. Order Value Analysis

Orders were aggregated to order grain and ranked according to their calculated total value.

The analysis then examined whether high-value orders were associated with:

* Number of order lines
* Total quantity
* Average unit price

### 5. Product Contribution Analysis

The highest-value orders were isolated using a subquery, after which their product composition was analysed.

This included calculating:

* Product quantity
* Product sales value
* Product contribution percentage

### 6. Online vs Non-Online Analysis

The `OnlineOrderFlag` field was used to compare online and non-online orders.

The analysis considered:

* Number of orders
* Average order value
* Average number of order lines
* Average quantity
* Average unit price

The analysis was then extended beyond averages to examine the underlying distribution of order values.

### 7. Distribution Analysis

Descriptive statistics were used to investigate the spread and skewness of order values.

The analysis included:

* Minimum
* First quartile (Q1)
* Median
* Mean
* Third quartile (Q3)
* Maximum
* Interquartile range (IQR)

This provides a more complete view of the data than relying on the mean alone.

---

## Key Findings

### High-Value Orders

The analysis indicates that high-value orders can arise from different combinations of quantity and unit price.

Quantity contributes substantially to total order value, but a high number of units alone does not necessarily produce the highest-value order. Unit price also has a material effect on the resulting order value.

### Product Contribution

Among the highest-value orders, sales value is distributed across multiple products rather than being concentrated in a single product.

The analysis also demonstrates that products with the highest quantities sold do not necessarily generate the highest sales value.

### Online vs Non-Online Orders

The analysis found a substantial difference in average order value between online and non-online orders.

| Order Type | Number of Orders | Average Order Value |
| ---------- | ---------------: | ------------------: |
| Non-online |            3,806 |           21,286.18 |
| Online     |           27,659 |            1,061.45 |

Further analysis showed that non-online orders contain considerably more order lines and units per order, while their average unit price is not higher than that of online orders.

This indicates that the difference in order value is strongly associated with **order volume and order composition**, rather than simply higher unit prices.

### Distribution of Order Values

The distribution analysis showed that both order types are right-skewed, with the mean exceeding the median.

| Order Type |      Min |       Q1 |   Median |      Mean |        Q3 |        Max |
| ---------- | -------: | -------: | -------: | --------: | --------: | ---------: |
| Online     |     2.29 |    46.47 |   594.97 |  1,061.45 |  2,181.56 |   3,578.27 |
| Non-online | 1,374.00 | 1,564.84 | 8,366.02 | 21,286.18 | 34,242.29 | 175,753.21 |

The quartiles and IQR provide additional context around the large difference in mean order value and demonstrate why distributional analysis is important when interpreting averages.

---

## SQL Concepts Demonstrated

This project demonstrates practical use of:

```text
SELECT
FROM
WHERE
INNER JOIN
LEFT JOIN
GROUP BY
HAVING
ORDER BY
TOP
Aggregate functions
Subqueries
Common Table Expressions (CTEs)
Window functions
PERCENTILE_CONT
PARTITION BY
```

A major focus of the project is understanding **data grain** and how it changes throughout an analysis.

For example:

```text
Order Detail
1 row = 1 order line
        ↓
Aggregation
        ↓
Order Level
1 row = 1 order
        ↓
Aggregation
        ↓
Order Type
1 row = Online / Non-online
```

---

## Project Structure

```text
AdventureWorks2022-SQL-Analysis/
│
├── README.md
│
├── ERD/
│   └── AdventureWorks2022_ERD.png
│
├── SQL/
│   ├── 01_data_exploration.sql
│   ├── 02_relationship_analysis.sql
│   ├── 03_order_value_analysis.sql
│   └── 04_online_order_analysis.sql
│
└── PowerBI/
    └──
```

---

## Tools & Technologies

* **Microsoft SQL Server**
* **SQL Server Management Studio (SSMS)**
* **SQL**
* **Git**
* **GitHub**
* **Power BI** — planned for visualization and reporting

---

## Project Status

### Completed

* [x] Database and table exploration
* [x] Table grain identification
* [x] ERD development
* [x] Primary key validation
* [x] Foreign key integrity checks
* [x] Table relationship analysis
* [x] Order-level aggregation
* [x] High-value order analysis
* [x] Product contribution analysis
* [x] Online vs non-online order analysis
* [x] Descriptive statistics
* [x] Percentile and IQR analysis

### In Progress

* [ ] Organise and document SQL scripts
* [ ] Push SQL analysis to GitHub
* [ ] Develop Power BI visualisations
* [ ] Build final analytical dashboard

---

## Purpose of the Project

This project was developed as a practical exercise in applying SQL to a relational dataset rather than simply demonstrating isolated SQL syntax.

Particular emphasis is placed on understanding **why** a query is structured a certain way, how table relationships affect the analysis, how aggregation changes data grain, and how different statistical measures can lead to different interpretations of the same dataset.
