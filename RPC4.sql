----- Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region----
SELECT 
	DISTINCT(market) FROM dim_customer 
WHERE customer = "Atliq Exclusive" AND region = "APAC";

----  What is the percentage of unique product increase in 2021 vs. 2020? -----
WITH CTE1 AS(
SELECT 
	COUNT(DISTINCT product_code) AS unique_products_2021 FROM dim_product 
	JOIN fact_sales_monthly USING (product_code) 
	WHERE fiscal_year =2021),
CTE2 AS (
SELECT 
	COUNT(DISTINCT product_code) AS unique_products_2020 FROM dim_product 
	JOIN fact_sales_monthly USING (product_code) 
	WHERE fiscal_year =2020)
SELECT  unique_products_2020, 
		unique_products_2021, 
		CONCAT(ROUND(((unique_products_2021 - unique_products_2020)/unique_products_2020)*100,2),"%") AS percent_chng
FROM CTE1,CTE2;

----  Provide a report with all the unique product counts for each  segment  and sort them in descending order of product counts.----
SELECT  DISTINCT (segment), 
		COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

----  Which segment had the most increase in unique products in 2021 vs 2020?
WITH CTE1 AS (
			SELECT  DISTINCT (segment), 
				COUNT(DISTINCT product_code) AS product_count_2021
			FROM dim_product
			JOIN fact_sales_monthly USING (product_code)
			WHERE fiscal_year=2021 
			GROUP BY segment
			ORDER BY product_count_2021 DESC),
CTE2 AS (
			SELECT  DISTINCT (segment), 
					COUNT(DISTINCT product_code) AS product_count_2020
			FROM dim_product
			JOIN fact_sales_monthly USING (product_code)
			WHERE fiscal_year=2020 
			GROUP BY segment
			ORDER BY product_count_2020 DESC)
SELECT  segment,
		product_count_2021,
        product_count_2020,
        (product_count_2021 - product_count_2020) AS difference
FROM CTE1
JOIN CTE2
USING (segment)
ORDER BY difference DESC;

----  Get the products that have the highest and lowest manufacturing costs. ----
SELECT product_code, product, manufacturing_cost
FROM fact_manufacturing_cost
JOIN dim_product
USING (product_code)
WHERE manufacturing_cost = (
	SELECT MAX(manufacturing_cost)
    FROM fact_manufacturing_cost )
    
UNION ALL 

SELECT product_code, product, manufacturing_cost
FROM fact_manufacturing_cost
JOIN dim_product
USING (product_code)
WHERE manufacturing_cost = (
	SELECT MIN(manufacturing_cost)
    FROM fact_manufacturing_cost);
 
-----  Generate a report which contains the top 5 customers who received an average 
------ high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian  market. ----
SELECT 	customer_code, 
		customer, 
		CONCAT(ROUND(AVG(pre_invoice_discount_pct)*100,2),"%") AS average_discount_percentage
FROM fact_pre_invoice_deductions
JOIN dim_customer
USING (customer_code)
WHERE   market ="INDIA" AND 
		fiscal_year = 2021
GROUP BY customer_code, customer
ORDER BY AVG(pre_invoice_discount_pct) DESC
LIMIT 5;

-----  Get the complete report of the Gross sales amount for the customer  “Atliq Exclusive”  for each month. ----
SELECT  MONTHNAME (s.date) AS Month, 
		CONCAT(FORMAT(SUM(s.sold_quantity * p.gross_price)/1000000,2),"M") AS gross_sales_amount, 
        s.fiscal_year AS Year
FROM fact_sales_monthly s
JOIN dim_customer c
ON s.customer_code = c.customer_code
JOIN fact_gross_price p
ON s.product_code = p.product_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY date,s.fiscal_year
ORDER BY YEAR, MONTH(s.date);

----  In which quarter of 2020, got the maximum total_sold_quantity?----
WITH CTE1 AS (
	SELECT CASE
		WHEN MONTH(date) IN (9,10,11) THEN "Q1"
        WHEN MONTH(date) IN (12,1,2) THEN "Q2"
        WHEN MONTH(date) IN (3,4,5) THEN "Q3"
        WHEN MONTH(date) IN (6,7,8) THEN "Q4"
			END AS Quarter,fiscal_year,
		CONCAT(FORMAT(SUM(sold_quantity)/1000000,2),"M") AS total_sold_quantity
	FROM fact_sales_monthly
    WHERE fiscal_year=2020
    GROUP BY Quarter,fiscal_year)
    
SELECT Quarter, total_sold_quantity FROM CTE1
ORDER BY total_sold_quantity DESC;

----  Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?---
WITH channelsales AS (
	SELECT  c.channel, 
			SUM(s.sold_quantity * p.gross_price) AS gross_sales
	FROM fact_sales_monthly s
	JOIN dim_customer c
	ON s.customer_code = c.customer_code
	JOIN fact_gross_price p
	ON s.product_code = p.product_code
	WHERE s.fiscal_year=2021
	GROUP BY c.channel ),
    
totalsales AS (
	SELECT SUM(gross_sales) AS total_gross_sales
    FROM channelsales)
    
SELECT channel, 
		CONCAT(ROUND(gross_sales/1000000,2),"M") AS gross_sales_mln,
		CONCAT(ROUND(((gross_sales / total_gross_sales))*100,2),"%") AS percentage
FROM channelsales, totalsales
ORDER BY percentage DESC;

-----  Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? ----
WITH productsold AS (
	SELECT  p.division, p.product_code, p.product,
			SUM(s.sold_quantity) AS total_sold_quantity
	FROM dim_product p
	JOIN fact_sales_monthly s
	USING(product_code)
	WHERE fiscal_year = 2021
	GROUP BY p.division, p.product_code, p.product ),

productrank AS (
	SELECT ps.division, ps.product_code, ps.product, ps.total_sold_quantity,
		RANK () OVER(PARTITION BY division ORDER BY ps.total_sold_quantity DESC) AS rank_order
    FROM productsold ps)

SELECT division, product_code, product, total_sold_quantity, rank_order 
FROM productrank
WHERE rank_order<=3
ORDER BY division, rank_order;



