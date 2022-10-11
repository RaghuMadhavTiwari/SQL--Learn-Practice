CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
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
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
/* --------------------
   Case Study Questions
   --------------------*/
SELECT
  	product_id,
    product_name,
    price
FROM menu
ORDER BY price DESC
LIMIT 5;

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id ,SUM(price)
FROM sales as s
INNER JOIN menu as m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id , COUNT(DISTINCT(order_date))
FROM sales 
GROUP BY customer_id
ORDER BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT customer_id, product_name
FROM
(
SELECT customer_id, order_date, product_name,DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) as item_rank
FROM sales as s
INNER JOIN menu as m
ON s.product_id=m.product_id
) as rank_table  
WHERE rank_table.item_rank=1
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name , order_count
FROM
  (SELECT product_name ,count(sales.product_id) AS order_count,
          rank() over(ORDER BY count(sales.product_id) DESC) AS order_rank
   FROM menu
   INNER JOIN sales ON menu.product_id = sales.product_id
   GROUP BY product_name) item_counts
WHERE order_rank=1;


-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_name
FROM
(
SELECT s.customer_id, product_name, 
	RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id)) as rnk
FROM sales as s
JOIN menu as m ON s.product_id = m.product_id
GROUP BY customer_id, product_name
) AS order_rnk
WHERE RNK=1
GROUP BY customer_id, product_name


-- 6. Which item was purchased first by the customer after they became a member?
WITH after_mem_orders AS
(
SELECT s.customer_id, s.product_id, s.order_date, 
	RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as rnk
FROM sales as s
JOIN members as mm
ON s.customer_id=mm.customer_id
WHERE s.order_date > mm.join_date
)
SELECT amo.customer_id, menu.product_name
FROM after_mem_orders as amo
JOIN menu 
ON menu.product_id=amo.product_id
WHERE rnk=1

-- 7. Which item was purchased just before the customer became a member?
WITH after_mem_orders AS
(
SELECT s.customer_id, s.product_id, s.order_date, 
	RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as rnk
FROM sales as s
JOIN members as mm
ON s.customer_id=mm.customer_id
WHERE s.order_date > mm.join_date
)
SELECT amo.customer_id, menu.product_name
FROM after_mem_orders as amo
JOIN menu 
ON menu.product_id=amo.product_id
WHERE rnk=1

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id) as Totalorders, SUM(m.price) as AmountSpent
FROM members as mm
JOIN sales as s
ON s.customer_id=mm.customer_id
JOIN menu as m
ON m.product_id=s.product_id
WHERE s.order_date < mm.join_date
GROUP BY s.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier how many points would each customer have?
SELECT s.customer_id, 
	SUM(CASE WHEN m.product_name='sushi' THEN price*20
	   	ELSE price*10
	   END) as totalpoints 
FROM sales as s
JOIN menu as m
ON m.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id, 
SUM(CASE WHEN s.order_date > mm.join_date THEN price*20
	WHEN s.order_date < mm.join_date AND m.product_name='sushi' THEN price*20
	ELSE price*10 
	END) as Points
FROM menu as m
JOIN sales as s
ON m.product_id = s.product_id
JOIN members as mm
ON mm.customer_id = s.customer_id
GROUP BY s.customer_id
ORDER BY s.customer_id
  
  
  
  