#Request1
-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
#Query
SELECT DISTINCT(market)
FROM gdb023.dim_customer
WHERE region = 'APAC' AND customer = 'Atliq Exclusive';

#Request2
/*What is the percentage of unique product increase in 2021 vs. 2020?
The final output contains these fields,
	unique_products_2020
	unique_products_2021
	percentage_chg*/
#Query
WITH CTE_2020 AS
(SELECT COUNT(DISTINCT product_code) AS unique_products_2020
FROM gdb023.fact_sales_monthly
WHERE fiscal_year = 2020),
CTE_2021 AS
(SELECT COUNT(DISTINCT product_code) AS unique_products_2021
FROM gdb023.fact_sales_monthly
WHERE fiscal_year = 2021)
SELECT unique_products_2020, unique_products_2021,
ROUND((unique_products_2021 - unique_products_2020)*100/unique_products_2020,2) AS percentage_chg
FROM CTE_2020
CROSS JOIN CTE_2021;

#Request3
/*Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields - segment,product_count*/
#Query
SELECT segment, COUNT(DISTINCT product_code) AS product_count
FROM gdb023.dim_product
GROUP BY segment
ORDER BY product_count DESC;

#Request4
/*Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
	segment
	product_count_2020
	product_count_2021
	difference*/
#Query
WITH CTE_2020 AS
(SELECT P.segment, COUNT(DISTINCT s.product_code) AS product_count_2020
FROM gdb023.dim_product AS p
JOIN gdb023.fact_sales_monthly AS S
ON p.product_code = s.product_code
WHERE s.fiscal_year = 2020
GROUP BY p.segment),
CTE_2021 AS
(SELECT P.segment, COUNT(DISTINCT s.product_code) AS product_count_2021
FROM gdb023.dim_product AS p
JOIN gdb023.fact_sales_monthly AS S
ON p.product_code = s.product_code
WHERE s.fiscal_year = 2021
GROUP BY p.segment)
SELECT CTE_2020.segment, product_count_2020, product_count_2021,
(product_count_2021 - product_count_2020) AS difference
FROM CTE_2020
JOIN CTE_2021
ON CTE_2020.segment = CTE_2021.segment
ORDER BY difference DESC;

#Request5
/*Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
	product_code
	product
	manufacturing_cost*/
#Query
SELECT dp.product_code, dp.product, fm.manufacturing_cost
FROM gdb023.dim_product AS dp
INNER JOIN gdb023.fact_manufacturing_cost AS fm
ON dp.product_code = fm.product_code
WHERE fm.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM gdb023.fact_manufacturing_cost)
OR
fm.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM gdb023.fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

#Request6
/*Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
	customer_code
	customer
	average_discount_percentage*/
#Query
SELECT c.customer, pre.customer_code, round(avg(pre.pre_invoice_discount_pct),2) AS avg_pct
FROM gdb023.fact_pre_invoice_deductions pre
JOIN gdb023.dim_customer c
ON c.customer_code = pre.customer_code
WHERE c.market = 'India' AND pre.fiscal_year = 2021
GROUP BY customer_code, customer
ORDER BY avg_pct DESC
LIMIT 5;

#Request7
/*Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
	Month
	Year
	Gross sales Amount*/
#Query
SELECT year(date) AS Year, month(date) AS Month, c.customer,
	 ROUND(SUM(s.sold_quantity * gp.gross_price),2) AS gross_price_amt
FROM gdb023.fact_sales_monthly AS s
JOIN gdb023.fact_gross_price gp
ON gp.product_code = s.product_code
JOIN gdb023.dim_customer AS c
ON c.customer_code = s.customer_code
WHERE c.customer = 'Atliq Exclusive'
GROUP BY Month, Year;

#Request8
/*In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
	Quarter
	total_sold_quantity*/
#Query
SELECT 
      CASE 
      WHEN month(s.date) in (9,10,11) then '1st Quarter'
      WHEN month(s.date) in (12,1,2) then '2nd Quarter'
      WHEN month(s.date) in (3,4,5) then '3rd Quarter'
      WHEN month(s.date) in (6,7,8) then '4th Quarter' END
      AS Quarter,
      sum(s.sold_quantity) AS Total_Sold_Quantity 
      FROM gdb023.fact_sales_monthly s
      WHERE s.fiscal_year = 2020
      GROUP BY Quarter
      ORDER BY Total_Sold_Quantity DESC;
      
#Request9
/*Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
	channel
	gross_sales_mln
	percentage*/
#Query
WITH CTE1 AS
      (SELECT 
      channel AS Channel, 
      round(sum(gp.gross_price*s.sold_quantity)/1000000,2) AS Gross_Sales_mln
      FROM gdb023.dim_customer c JOIN gdb023.fact_sales_monthly s
      ON c.customer_code = s.customer_code
      JOIN gdb023.fact_gross_price gp
      ON gp.product_code = s.product_code
      WHERE s.fiscal_year = 2021
      GROUP BY channel
      ORDER BY Gross_Sales_mln DESC)

      SELECT *,ROUND(Gross_Sales_mln*100/sum(Gross_Sales_mln) OVER(), 2)
      AS Percentage
      FROM CTE1
      
#Request10
/*Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
	division
	product_code*/
#Query
WITH CTE1 AS
      (SELECT 
      p.division, p.product_code, p.product, 
      sum(s.sold_quantity) AS Total_Sold_Quantity
      FROM gdb023.dim_product p JOIN gdb023.fact_sales_monthly s
      ON p.product_code = s.product_code
      WHERE s.fiscal_year = 2021
      GROUP BY division, p.product_code, p.product),

      CTE2 AS
      (SELECT *, RANK()
      OVER(PARTITION BY division ORDER BY Total_Sold_Quantity DESC) AS Rank_Order
      FROM CTE1)
      SELECT * FROM CTE2
      WHERE Rank_Order < 4;



