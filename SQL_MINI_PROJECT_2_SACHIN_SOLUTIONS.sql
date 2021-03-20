 #SQL II - Mini Project
#_________________________________________________________
#Composite data of a business organisation, confined to ‘sales and delivery’
#domain is given for the period of last decade. From the given data retrieve
#solutions for the given scenario.
use mini_project2;
select * from combined_table;
select * from cust_dimen;
select * from market_fact;
select * from orders_dimen1;
select * from prod_dimen;
select * from shipping_dimen1;
#1. Join all the tables and create a new table called combined_table.
#(market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
create table combined_table as(
select c.Cust_id,Province,Region,Customer_Segment,o.Order_ID, order_date,order_priority,
p.prod_id,Product_Category,Product_sub_Category,s.Ship_id,ship_date,ship_mode,
Sales,Discount,Order_Quantity,Profit,Shipping_Cost,Product_Base_Margin
from market_fact m  join cust_dimen c
on m.cust_id=c.cust_id
join orders_dimen1 o on m.ord_id=o.ord_id
join prod_dimen p on m.prod_id=p.prod_id
join shipping_dimen1 s on m.ship_id = s.ship_id);

#2. Find the top 3 customers who have the maximum number of orders
select customer_name, order_quantity from cust_dimen c
join market_fact m
on c.cust_id = m.cust_id 
group by order_quantity 
order by order_quantity desc limit 3;

#3. Create a new column DaysTakenForDelivery that contains the date difference
#of Order_Date and Ship_Date.
select s.order_id,abs(datediff(o.order_date,s.ship_date)) as DaysTakenForDelivery from market_fact m 
join shipping_dimen1 s
on s.ship_id = m.ship_id
join orders_dimen1 o on m.ord_id=o.ord_id;

#4. Find the customer whose order took the maximum time to get delivered.
SELECT CUSTOMER_NAME, DaysTakenForDelivery FROM (SELECT ORD_ID,ABS(datediff(S1.Order_Date,S2.Ship_Date)) DaysTakenForDelivery FROM orders_dimen1 S1
JOIN shipping_dimen1 S2
ON S1.ORDER_ID=S2.ORDER_ID
GROUP BY ORD_ID) T1
JOIN market_fact T2
ON T1.ORD_ID=T2.ORD_ID
JOIN cust_dimen T3
ON T3.CUST_ID=T2.CUST_ID
WHERE DaysTakenForDelivery IN (SELECT MAX(DaysTakenForDelivery) FROM (SELECT ORD_ID,ABS(datediff(S1.Order_Date,S2.Ship_Date)) DaysTakenForDelivery FROM orders_dimen1 S1
JOIN shipping_dimen1 S2
ON S1.ORDER_ID=S2.ORDER_ID
GROUP BY ORD_ID) T2) ;

#5. Retrieve total sales made by each product from the data (use Windows
#function)
select distinct(prod_id), product_sub_category, sum(sales) over(partition by prod_id) as total_sales from combined_table;
#6. Retrieve total profit made from each product from the data (use windows
#function)
select distinct(prod_id), product_sub_category, sum(profit) over(partition by prod_id) as total_sales from combined_table;
#7. Count the total number of unique customers in January and how many of them
#came back every month over the entire year in 2011
SELECT C2 unique_customers_in_January, T1.C1-T2.C2 CUSTOMER_CAME_BACK_AFTER_JANUARY FROM 
(SELECT COUNT(distinct CUST_ID) C1 FROM combined_table WHERE ORDER_DATE LIKE "2011%") T1 
INNER JOIN 
(SELECT COUNT(distinct CUST_ID) C2 FROM combined_table WHERE ORDER_DATE LIKE "2011-01%") T2
ON 1=1;
#8. Retrieve month-by-month customer retention rate since the start of the
#business.(using views)
CREATE OR REPLACE VIEW retention_rate AS
SELECT MONTHNAME(MM) ,DaysTakenForDelivery,
case
WHEN DaysTakenForDelivery=1 THEN "RETAINED"
WHEN DaysTakenForDelivery>1 THEN "IRREGULAR"
ELSE "CHURNED"
END OUTPUT

 FROM (SELECT S1.Order_Date MM, ORD_ID,ABS(datediff(S1.Order_Date,S2.Ship_Date)) DaysTakenForDelivery FROM orders_dimen1 S1
JOIN shipping_dimen1 S2
ON S1.ORDER_ID=S2.ORDER_ID
GROUP BY ORD_ID) T1
GROUP BY MM ORDER BY MM
;
#Tips:
#1: Create a view where each user’s visits are logged by month, allowing for
#the possibility that these will have occurred over multiple # years since
#whenever business started operations
# 2: Identify the time lapse between each visit. So, for each person and for each
#month, we see when the next visit is.
# 3: Calculate the time gaps between visits
# 4: categorise the customer with time gap 1 as retained, >1 as irregular and
#NULL as churned
# 5: calculate the retention month wise
