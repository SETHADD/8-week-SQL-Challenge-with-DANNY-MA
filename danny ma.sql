
  -- 1. What is the total amount each customer spent at the restaurant?

  SELECT s.customer_id, sum(m.price)
 FROM dbo.sales s
 join dbo.menu m
 on s.product_id = m.product_id
 group by s.customer_id

 -- 2. How many days has each customer visited the restaurant?

 select customer_id,
 count(distinct order_date) #_of_times
 from dbo.sales
 group by customer_id

 --3. What was the first item from the menu purchased by each customer?

with nan as (select s.customer_id,s.order_date,m.product_name,
case 
when lag(customer_id) over(partition by customer_id order by order_date) = customer_id then null else customer_id end as Tab
from dbo.sales s
join dbo.menu m
on s.product_id = m.product_id)

select nan.customer_id,nan.order_date,nan.product_name
from nan
where nan.tab is not null

--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

---code to find most purchased item
select m.product_name,count(m.product_name) #orders
from dbo.sales s
join menu m
on m.product_id = s.product_id
group by m.product_name

---code to find how many times per customer
--- take the customer_id out to get count for all customers

select  s.customer_id,m.product_name,count(m.product_name) #orders
from dbo.sales s
join menu m
on m.product_id = s.product_id
where m.product_name = 'ramen'
group by m.product_name, s.customer_id
order by count(m.product_name) desc

-- 5. Which item was the most popular for each customer?

select s.customer_id,m.product_name,count(m.product_name) #orders
from dbo.sales s
join menu m
on m.product_id = s.product_id
group by s.customer_id,m.product_name
order by count(m.product_name) desc, s.customer_id

-- 6. Which item was purchased first by the customer after they became a member?

with ftable as (SELECT  s.customer_id,m.join_date,s.order_date,me.product_name,
case 
when lag(s.customer_id) over(partition by s.customer_id order by s.customer_id) = s.customer_id then null else s.customer_id end as Tab1
  FROM [master].[dbo].[members] m
  inner join dbo.sales s
  on m.customer_id = s.customer_id 
  join dbo.menu me
  on me.product_id = s.product_id
  where (s.order_date >= '2021-01-07' AND s.customer_id = 'A') OR (s.order_date >= '2021-01-09' AND s.customer_id = 'B')
)

select ftable.customer_id,ftable.product_name
from ftable
where Tab1 is not null 
  order by ftable.order_date

-- 7. Which item was purchased just before the customer became a member?

WITH ntable as (SELECT  s.customer_id,m.join_date,s.order_date,me.product_name,
case 
when lead(s.customer_id) over(partition by s.customer_id order by s.customer_id) = s.customer_id then null else s.customer_id end as Tab2
  FROM [master].[dbo].[members] m
  inner join dbo.sales s
  on m.customer_id = s.customer_id 
  join dbo.menu me
  on me.product_id = s.product_id
  where (s.order_date < '2021-01-07' AND s.customer_id = 'A') OR (s.order_date < '2021-01-09' AND s.customer_id = 'B')
  )
  select ntable.customer_id,ntable.product_name
  from ntable
  where tab2 is not null

-- 8. What is the total items and amount spent for each member before they became a member?

with n3table as (SELECT  s.customer_id,me.price,m.join_date,s.order_date,me.product_name,
  sum(me.price) over(partition by s.customer_id) total_spent,
  count(s.customer_id) over(partition by s.customer_id) #_of_times
  FROM [master].[dbo].[members] m
  inner join dbo.sales s
  on m.customer_id = s.customer_id 
  join dbo.menu me
  on me.product_id = s.product_id
  where (s.order_date < '2021-01-07' AND s.customer_id = 'A') OR (s.order_date < '2021-01-09' AND s.customer_id = 'B'))

  select n3table.customer_id,sum(n3table.#_of_times) total_items,sum(n3table.total_spent) amount_spent
  from n3table
  group by n3table.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with n1table as (select S.customer_id,me.product_name, me.price,
case
   when me.product_name = 'sushi' then me.price*20 else me.price*10 end AS points_per_customer
  FROM dbo.sales s
  join dbo.menu me
  on me.product_id = s.product_id )	

  select n1table.customer_id, sum(n1table.points_per_customer) total_points
  from n1table
  group by n1table.customer_id

  -- 10. In the first week after a customer joins the program (including their join date) 
  --they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


  with n2table AS (select s.customer_id,me.product_name,s.order_date,m.join_date,me.price, me.price*20 AS first_week_points
  FROM [master].[dbo].[members] m
  inner join dbo.sales s
  on m.customer_id = s.customer_id 
  join dbo.menu me
  on me.product_id = s.product_id
  where ((s.order_date >= '2021-01-07' AND s.customer_id = 'A') 
  OR (s.order_date >= '2021-01-09' AND s.customer_id = 'B'))
  AND s.order_date BETWEEN '2021-01-07' AND '2021-01-14'
  )
  select n2table.customer_id,SUM(n2table.first_week_points) total_points
  from n2table
  group by n2table.customer_id
 

