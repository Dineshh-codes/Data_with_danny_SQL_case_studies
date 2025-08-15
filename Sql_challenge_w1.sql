CREATE SCHEMA dannys_diner;
CREATE database DINESH;
drop DATABASE DINESH;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id  INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  select * from members;
  select * from menu;
  select * from sales;
  
  #1) Total spending by each customer
  
  with cte as (
  select * from sales
  join menu
  using (product_id))
  select customer_id, sum(price) as total_spending
  from cte
  group by customer_id;
  
  #2) how many visits each customer
  select customer_id,count(distinct order_date) as visits from  sales
  group by customer_id;
  
  #3) What was the first item from the menu purchased by each customer?
  with cte as (
  select *, rank() over(partition by customer_id order by order_date)  as rankk from sales join menu using (product_id)
  )
  select distinct customer_id,  product_name from cte where rankk=1;
  
with cte as (
  select customer_id,min(order_date) as order_date 
  from sales 
  group by customer_id,product_id)
  select customer_id, product_name from cte   join menu
  using (product_id)
  ;
  #4)What is the most purchased item on the menu and how many times was it purchased by all customers?
  select product_name,count(product_name) as top 
  from sales
  join menu 
  using (product_id)
  group by product_name
  order by top desc
  limit 1
  ;
  
  #5)Which item was the most popular for each customer?
  with cte as 
  (select customer_id, product_id , count(product_id)  as nuumber_of_orders, row_number() over(partition by customer_id order by count(product_id) desc) as rn from sales
  group by customer_id, product_id)
  select c.customer_id, m.product_id as most_popular_item
  from cte c 
  join menu m
  using (product_id)
  where rn=1       
  ;
  
#6)which item was purchased first by the customer after they became a member?
with cte as (
select s.*, rank() over(partition by customer_id order by order_date) as rnk from sales s 
join members m
using (customer_id) 
where s.order_date >= m.join_date)
select customer_id, product_name from cte c
join menu m 
using(product_id)
where c.rnk=1;


#7)Which item was purchased just before the customer became a member?

with cte as (
select s.*, rank() over(partition by customer_id order by order_date desc) as rnk from sales s 
join members m
using (customer_id) 
where s.order_date <m.join_date)
select c.customer_id, m.product_name  as first_order_before_member
from cte c 
join  menu m
using (product_id)
where c.rnk=1
order by customer_id;


#8)What is the total items and amount spent for each member before they became a member?
with cte as (
select s.*, rank() over(partition by customer_id order by order_date desc) as rnk from sales s 
join members m
using (customer_id) 
where s.order_date <m.join_date)
select c.customer_id, count(c.product_id) as no_of_items, sum(me.price) as amount_spent_before_membership
from cte c join menu me
using (product_id)
group by customer_id;

#9)If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id, 
	   sum( case when product_name in ("curry","ramen" ) then price * 10
			 else price * 20
        end) as points
from sales
join menu m
using (product_id)
group by customer_id;

#10)In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with cte as (select s.*,m.join_date, me.price,me.product_name, datediff(order_date,join_date) + 1 as days, 
	   case 
		    when datediff(order_date,join_date) between 0 and 6 then price *20
            when product_name in ("curry","ramen" ) then price * 10
		else price * 20
        end as points
from sales s
join members m
using( customer_id)
join menu me 
using(product_id)
where customer_id in("A","B")
)
select customer_id, sum(points) as total_points from cte
group by customer_id
order by customer_id;
  
#11) Table

select s.customer_id, s.order_date,me.product_name, case when s.order_date <= m.join_date then "Y" else "N" end as member
from sales s
join menu me
using(product_id)
left join members m
using(customer_id)
;

#12)
with cte as (
select s.customer_id, s.order_date,me.product_name, case when s.order_date <= m.join_date then "Y" else "N" end as members
from sales s
join menu me
using(product_id)
left join members m
using(customer_id))

select cte.*, if (members= "Y" , row_number() over(partition by customer_id order by order_date), NULL) as rankk
from cte
