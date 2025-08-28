use pizza_sales;

DATA EXPLORATION

Task 1: Retrieve the total number of orders placed.
SELECT 
    COUNT(order_id) AS total_orders
FROM
    orders;

Task 2: Calculate the total revenue generated from pizza sales.
SELECT 
    ROUND(SUM(o.quantity * p.price), 2) AS total_revenue
FROM
    order_details o
        INNER JOIN
    pizzas p ON o.pizza_id = p.pizza_id;

Task 3: Identify the highest-priced pizza.
SELECT 
    pt.name, p.price
FROM
    pizzas p
        LEFT JOIN
    pizza_types pt ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;

Task 4: Identify the most common pizza size ordered.
SELECT 
    p.size, SUM(od.quantity) AS no_of_size_ordered
FROM
    pizzas p
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY no_of_size_ordered DESC;

SALES ANALYSIS- CRUNCHING THE NUMBERS

Task 1: List the top 5 most ordered pizza types along with their quantities.
SELECT 
    pt.name, SUM(od.quantity) AS ordered_quantity
FROM
    pizza_types pt
        LEFT JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        LEFT JOIN
    order_details od ON od.pizza_id = p.pizza_id
GROUP BY pt.name
ORDER BY ordered_quantity DESC
LIMIT 5;

Task 2: Determine the distribution(hourly orders/total orders) of orders by hour of the day.
select *
 ,sum(hourly_orders) over () as total_orders
 ,hourly_orders *100/sum(hourly_orders) over() as distribution
from(
SELECT 
    HOUR(time) AS hour_of_day,
    COUNT(DISTINCT order_id) AS hourly_orders
FROM
    orders
GROUP BY HOUR(time)
) as a;

Task 3: Determine the top 3 most ordered pizza types based on revenue.
SELECT 
    pt.pizza_type_id,
    pt.name,
    SUM(p.price * od.quantity) AS revenue
FROM
    pizza_types pt
        LEFT JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        LEFT JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.pizza_type_id , pt.name
ORDER BY revenue DESC
LIMIT 3;

OPERATIONAL INSIGHTS

Task 1: Calculate the percentage contribution of each pizza type to total revenue.
with pizza_type_rev as (
SELECT 
    pt.name, ROUND(SUM(p.price * od.quantity), 2) AS revenue
FROM
    pizza_types pt
        LEFT JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        LEFT JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.name
ORDER BY revenue DESC)
select *,
round(sum(revenue) over(),2) as total_revenue,
round(revenue * 100.00/sum(revenue) over(),2) as distribution
from pizza_type_rev; 

Task 2: Analyze the cumulative revenue generated over time.
with cr_overtime as(
SELECT 
    o.date, ROUND(SUM(p.price * od.quantity), 2) AS revenue
FROM
    order_details od
        LEFT JOIN
    pizzas p ON od.pizza_id = p.pizza_id
        LEFT JOIN
    orders o ON od.order_id = o.order_id
group by o.date
order by o.date)
select *,
round(sum(revenue) over( order by date rows between unbounded preceding and current row),2) as cumulative_revenue
from cr_overtime;

Task 3: Determine the top 3 most ordered pizza types based on revenue for each pizza
category.
select *
from(
select *,
dense_rank() over(partition by category order by revenue desc) as rank_on_revenue
from(
SELECT 
    pt.category,
    pt.name,
    ROUND(SUM(p.price * od.quantity), 2) AS revenue
FROM
    pizza_types pt
        LEFT JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        LEFT JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.category , pt.name
)as tabl
)as tab
where rank_on_revenue<=3;

CATEGORY-WISE ANALYSIS

Task 1: Join the necessary tables to find the total quantity of each pizza category
ordered.
SELECT 
    pt.category, SUM(od.quantity) AS total_quantity
FROM
    pizza_types pt
        LEFT JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        LEFT JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.category;

Task 2: Join relevant tables to find the category-wise distribution of pizzas.
with Pizza_table as
( SELECT 
    pt.category, SUM(od.quantity) AS total_quantity
FROM
    pizza_types pt
        LEFT JOIN
    pizzas p ON pt.pizza_type_id = p.pizza_type_id
        LEFT JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY pt.category
) select *,
round(total_quantity*100/sum(total_quantity) over(),2) as distribution
from pizza_table ;

Task 3: Group the orders by the date and calculate the average number of pizzas
ordered per day.
SELECT 
    AVG(total_quantity) AS avg_no_pizza
FROM
    (SELECT 
        o.date, SUM(od.quantity) AS total_quantity
    FROM
        orders o
    LEFT JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.date) AS table1;
    
    select order_id,
    date_format(date) as year
    from orders;
    
Write a query to display each order_id along with the order month and year.
SELECT 
    order_id,
    MONTH(date) AS order_month,
    YEAR(date) AS order_year
FROM
    orders
;

Find the sales according to the hour of the day.(Bussiest hour on the top)
SELECT 
    HOUR(o.time) AS busy_hour,
    COUNT(o.order_id) AS total_order,
    ROUND(SUM(od.quantity * p.price), 2) AS total_sales
FROM
    orders o
        LEFT JOIN
    order_details od ON o.order_id = od.order_id
        LEFT JOIN
    pizzas p ON od.pizza_id = p.pizza_id
GROUP BY busy_hour
ORDER BY total_order DESC
;
Compare sales between weekdays and weekends.
SELECT 
    CASE
        WHEN DAYOFWEEK(o.date) IN (1 , 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_sales,
    ROUND(SUM(od.quantity * p.price), 2) AS total_sales
FROM
    orders o
        LEFT JOIN
    order_details od ON o.order_id = od.order_id
        LEFT JOIN
    pizzas p ON od.pizza_id = p.pizza_id
GROUP BY Day_sales
;
Find average daily sales.
SELECT 
    order_day, ROUND(AVG(total_sales), 2) AS avg_sales
FROM
    (SELECT 
        DATE(o.date) AS order_day,
            SUM(od.quantity * p.price) AS total_sales
    FROM
        orders o
    LEFT JOIN order_details od ON o.order_id = od.order_id
    LEFT JOIN pizzas p ON od.pizza_id = p.pizza_id
    GROUP BY order_day
    ORDER BY order_day) AS table1
GROUP BY order_day;

Find the month with the highest number of orders.
SELECT 
    MONTH(date) AS order_month,
    COUNT(DISTINCT order_id) AS total_orders
FROM
    orders
GROUP BY order_month
ORDER BY total_orders DESC
LIMIT 1;

Get total revenue in each quarter.
SELECT 
    CONCAT('Q', QUARTER(o.date), ' ', YEAR(o.date)) AS per_quarter,
    SUM(quantity * price) AS total_revenue
FROM
    orders o
        LEFT JOIN
    order_details od ON o.order_id = od.order_id
        LEFT JOIN
    pizzas p ON od.pizza_id = p.pizza_id
GROUP BY per_quarter
ORDER BY Per_quarter;
SELECT 
    *
FROM
    pizzas;
