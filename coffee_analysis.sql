create database coffee_nations;

use coffee_nations;

select * from city;
select * from customers;
select * from products;
select * from sales;

/* 1.Coffee Consumers Count
How many people in each city are estimated to consume coffee, given that 25% of the population does? */

select 
city_name,
round((population * 0.25)/1000000,2) as coffee_consumers_in_millions,
city_rank from city
order by population desc;

/* 2.Total Revenue from Coffee Sales
What is the total revenue generated from coffee sales across all cities in the last quarter of 2023? */

select *,
    extract(year from sale_date) as year,
    extract(quarter from sale_date) as qtr
from sales;  

select year,qtr,total_revenue from
(select 
    extract(year from sale_date) as year,
    extract(quarter from sale_date) as qtr,
    sum(total) as total_revenue
from sales
group by year,qtr
order by year,qtr) as a
where year = 2023 and qtr = 4;

-- revenue by city names
select
    sum(total) as total_revenue
from sales   
where extract(year from sale_date) = 2023 and
      extract(quarter from sale_date) = 4;
      
select ci.city_name,
    sum(s.total) as total_revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on c.city_id = ci.city_id  
where extract(year from s.sale_date) = 2023 and
      extract(quarter from s.sale_date) = 4
group by 1
order by 2 desc;

/* 3.Sales Count for Each Product
How many units of each coffee product have been sold? */      
   
select p.product_name,
    count(s.sale_id) as total_orders
from products as p
left join sales as s
on s.product_id = p.product_id
group by 1
order by 2 desc;

/* 4.Average Sales Amount per City
What is the average sales amount per customer in each city? */

select ci.city_name,
    sum(s.total) as total_revenue,
    count(distinct s.customer_id) as total_customers,
    round(sum(s.total)/count(distinct s.customer_id),2)as avg_sales_per_customer
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on c.city_id = ci.city_id  
group by 1 
order by 2 desc;

/* 5.City Population and Coffee Consumers
Provide a list of cities along with their populations and estimated coffee consumers.*/

WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;

/* 6.Top Selling Products by City
What are the top 3 selling products in each city based on sales volume? */


select * from
	(select 
		ct.city_name,
		p.product_name,
		count(s.sale_id) as total_orders,
		DENSE_RANK() OVER (PARTITION BY ct.city_name ORDER BY COUNT(s.sale_id) desc) as dense_rank_num
	from sales as s
	join products as p
	on s.product_id = p.product_id
	join customers as c
	on s.customer_id = c.customer_id
	join city as ct
	on c.city_id = ct.city_id
	group by 1,2) as t1
where dense_rank_num <= 3;


/* 7.Customer Segmentation by City
How many unique customers are there in each city who have purchased coffee products? */

SELECT 
    ci.city_name,
    count(distinct c.customer_id) as unique_cx
	FROM city as ci
	JOIN customers as c
	ON ci.city_id = c.city_id
	join sales as s
    on s.customer_id = c.customer_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)  
group by 1;  

-- alterantive solution using 'exists' --
SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_cx
FROM city AS ci
JOIN customers AS c ON ci.city_id = c.city_id
WHERE EXISTS (
    SELECT 1
    FROM sales AS s
    WHERE s.customer_id = c.customer_id AND s.product_id IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
)
GROUP BY ci.city_name;

/* 8.Average Sale vs Rent
Find each city and their average sale per customer and avg rent per customer. */

WITH city_table AS (
  SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_cx,
    ROUND(
      SUM(s.total) / COUNT(DISTINCT s.customer_id), 
      2
    ) AS avg_sale_pr_cx
   
  FROM sales AS s
  JOIN customers AS c ON s.customer_id = c.customer_id
  JOIN city AS ci ON ci.city_id = c.city_id
  GROUP BY ci.city_name
  ORDER BY total_revenue DESC
),
city_rent AS (
  SELECT 
    city_name, 
    estimated_rent
  FROM city
)
SELECT 
  cr.city_name,
  cr.estimated_rent,
  ct.total_cx,
  ct.avg_sale_pr_cx,
  ROUND(
    cr.estimated_rent / ct.total_cx, 
    2
  ) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY ct.avg_sale_pr_cx DESC;


/* 9.Monthly Sales Growth
Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly). */

with 
monthly_sale as
	(select 
		city_name,
		extract(month from sale_date) as month,
		 extract(year from sale_date) as year,
		 sum(s.total) as total_sale
	from sales as s
	join customers as c
	on c.customer_id = s.customer_id
	join city as ci
	on ci.city_id = c.city_id
	group by 1,2,3
	order by 1,3,2
),
growth_ratio as
(      select city_name,
			   month,
			   year,
			   total_sale as cr_month_sale,
			   lag(total_sale,1) over(partition by city_name order by year,month) as last_month_sale
		from monthly_sale
)
select city_name,
       year,
       month,
       cr_month_sale,
       last_month_sale,
       round((cr_month_sale-last_month_sale)/last_month_sale * 100,2) as growth_ratio
from growth_ratio
WHERE last_month_sale is not null;


/* 10.Market Potential Analysis
Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer. */

WITH city_table AS (
  SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_cx,
    ROUND(
      SUM(s.total) / COUNT(DISTINCT s.customer_id), 
      2
    ) AS avg_sale_pr_cx
   
  FROM sales AS s
  JOIN customers AS c ON s.customer_id = c.customer_id
  JOIN city AS ci ON ci.city_id = c.city_id
  GROUP BY ci.city_name
  ORDER BY total_revenue DESC
),
city_rent AS (
  SELECT 
    city_name, 
    estimated_rent,
    round((population * 0.25/1000000),3) as estimated_coffee_consumer_in_millions
  FROM city
)
SELECT 
  cr.city_name,
  total_revenue,
  cr.estimated_rent as total_rent,
  ct.total_cx,
  estimated_coffee_consumer_in_millions,
  ct.avg_sale_pr_cx,
  ROUND(
    cr.estimated_rent / ct.total_cx, 
    2
  ) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
ON cr.city_name = ct.city_name
ORDER BY total_revenue DESC;

/* 
recommendations

After analyzing the data, the recommended top three cities for new store openings are:

City 1: Pune

Average rent per customer is very low.
Highest total revenue.
Average sales per customer is also high.
City 2: Delhi

Highest estimated coffee consumers at 7.7 million.
Highest total number of customers, which is 68.
Average rent per customer is 330 (still under 500).
City 3: Jaipur

Highest number of customers, which is 69.
Average rent per customer is very low at 156.
Average sales per customer is better at 11.6k.

end
*/
  
       