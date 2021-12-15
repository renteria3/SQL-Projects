/* 
Retailer Advertising: Best Way to Target Consumers to Increase Sales

Skills used: Case, Joins, CTE's, Windows Functions, Aggregate Functions, Converting Data Types

*/
USE Portfolio_Project

--Exploring the Data
SELECT * FROM dbo.consumer$
SELECT * FROM dbo.purchase$
SELECT * FROM dbo.email$
SELECT * FROM dbo.pop_up$

SELECT MAX(sales_amount_total) AS max_sales, MIN(sales_amount_total) AS min_sales, 
	AVG(sales_amount_total) AS avg_sales FROM dbo.purchase$

--Demographic per gender
SELECT gender, COUNT(gender) AS TotalPerGender
	FROM dbo.consumer$
	GROUP BY gender

--Demographic per Loyalty Status
SELECT loyalty_status, COUNT(loyalty_status) AS TotalPerStatus
	FROM dbo.consumer$
	GROUP BY loyalty_status
	ORDER BY loyalty_status

SELECT pop_up, COUNT(pop_up) AS TotalPopUP
	FROM pop_up$
	GROUP BY pop_up

SELECT saved_discount, COUNT(saved_discount) AS TotalDiscount
	FROM pop_up$
	GROUP BY saved_discount

--Demographic by Gender and Age
SELECT gender, COUNT(*) AS gender_count, AVG(age) AS average_age
		FROM consumer$
	GROUP BY gender

--Demographic by Loyalty Status & Age
SELECT loyalty_status, COUNT(*) AS loyalty_count, AVG(age) AS average_age
		FROM consumer$
	GROUP BY loyalty_status
	ORDER BY loyalty_status

--Rolling Sales Total by Loyalty Status
SELECT con.consumer_id, con.age, con.gender, con.loyalty_status, pur.sales_amount_total,
	SUM(pur.sales_amount_total) OVER (PARTITION BY con.loyalty_status ORDER BY pur.sales_amount_total) AS rolling_sales_total
		FROM consumer$ AS con
	JOIN purchase$ AS pur ON con.consumer_id = pur.consumer_id

--Average Sales
SELECT AVG(sales_amount_total) AS average_sales
	FROM purchase$

--Amount of Open Emails vs NOT
SELECT opened_email, COUNT(*) AS consumer_count
	FROM email$
	GROUP BY opened_email

SELECT em.opened_email, con.gender, COUNT(con.gender) AS consumer_count 
		FROM email$ AS em
	INNER JOIN consumer$ AS con ON con.consumer_id = em.consumer_id
	GROUP BY opened_email, con.gender

--Amount of Open Emails vs NOT (Percentage per Gender via CTE)
WITH OpenedvsGender as
(
SELECT DISTINCT em.opened_email, con.gender, COUNT(con.gender) 
	OVER (PARTITION BY opened_email, con.gender) AS consumer_count 
		FROM email$ AS em
	INNER JOIN consumer$ AS con ON con.consumer_id = em.consumer_id)
SELECT *, ROUND((CAST(consumer_count AS DECIMAL)/9032)*100,2) AS percent_of_total
	FROM OpenedvsGender

--Sales for Pop Up Received vs Not	
SELECT pop.pop_up, SUM(pur.sales_amount_total) AS total_sales, AVG(pur.sales_amount_total) AS avg_sales
		FROM pop_up$ AS pop
	INNER JOIN purchase$ AS pur ON pop.consumer_id = pur.consumer_id
	INNER JOIN consumer$ AS con ON pop.consumer_id = con.consumer_id
	GROUP BY pop.pop_up
	
SELECT DISTINCT pop.pop_up, con.gender, 
	COUNT(con.gender) OVER (PARTITION BY pop.pop_up, con.gender) AS consumer_count, 
	SUM(pur.sales_amount_total) OVER (PARTITION BY pop.pop_up, con.gender) AS total_sales, 
	AVG(pur.sales_amount_total) OVER (PARTITION BY pop.pop_up, con.gender) AS avg_sales
		FROM pop_up$ AS pop
	INNER JOIN purchase$ AS pur ON pop.consumer_id = pur.consumer_id
	INNER JOIN consumer$ AS con ON pop.consumer_id = con.consumer_id

SELECT SUM(sales_amount_total) FROM purchase$	

--Sales for Pop Up Received vs Not (Percentage of Total Sales per Gender via CTE)
WITH PopupvsGender as
(
SELECT DISTINCT pop.pop_up, con.gender, 
	COUNT(con.gender) OVER (PARTITION BY pop.pop_up, con.gender) AS consumer_count, 
	SUM(pur.sales_amount_total) OVER (PARTITION BY pop.pop_up, con.gender) AS total_sales, 
	AVG(pur.sales_amount_total) OVER (PARTITION BY pop.pop_up, con.gender) AS avg_sales
		FROM pop_up$ AS pop
	INNER JOIN purchase$ AS pur ON pop.consumer_id = pur.consumer_id
	INNER JOIN consumer$ AS con ON pop.consumer_id = con.consumer_id
)
SELECT pop_up, gender, consumer_count, total_sales, ROUND((total_sales/1221254.32)*100,2) AS percent_of_total, avg_sales 
	FROM PopupvsGender

--Sales per Consumer
SELECT pop.consumer_id, pur.sales_amount_total
		FROM pop_up$ AS pop
	INNER JOIN purchase$ AS pur ON pop.consumer_id = pur.consumer_id
	WHERE pop.pop_up = 1
	ORDER BY pur.sales_amount_total

--Sales for Opened Email vs Not
SELECT em.opened_email, SUM(pur.sales_amount_total) AS total_sales, AVG(pur.sales_amount_total) AS avg_sales
		FROM email$ AS em
	INNER JOIN purchase$ AS pur ON em.consumer_id = pur.consumer_id
	GROUP BY em.opened_email

--subqueries showing top 5 consumers that opened email vs didnt open email
SELECT TOP 5 consumer_id, sales_amount_total
		FROM purchase$
	WHERE consumer_id IN (
		SELECT consumer_id
		FROM email$
		WHERE opened_email = 1) 
	ORDER BY sales_amount_total DESC 

SELECT TOP 5 consumer_id, sales_amount_total
		FROM purchase$
	WHERE consumer_id IN (
		SELECT consumer_id
		FROM email$
		WHERE opened_email = 0) 
	ORDER BY sales_amount_total DESC

--subqueries showing bottom 5 consumers that opened email vs didnt open email
SELECT TOP 5 consumer_id, sales_amount_total
		FROM purchase$
	WHERE consumer_id IN (
		SELECT consumer_id
		FROM email$
		WHERE opened_email = 1) 
	ORDER BY sales_amount_total  

SELECT TOP 5 consumer_id, sales_amount_total
		FROM purchase$
	WHERE consumer_id IN (
		SELECT consumer_id
		FROM email$
		WHERE opened_email = 0) 
	ORDER BY sales_amount_total 

--Create categories for consumers on how much they spent (low, meduim, high)
ALTER TABLE purchase$
	ADD Purchase_Level VARCHAR(255)

UPDATE purchase$	
	SET Purchase_Level = CASE 
		 WHEN sales_amount_total < 50.01 THEN 'Low'
		 WHEN sales_amount_total BETWEEN 50.01 AND 100 THEN 'Medium'
 		 WHEN sales_amount_total BETWEEN 100.01 AND 500 THEN 'High'
		 ELSE 'Extreme'
		 END

SELECT Purchase_Level, COUNT(Purchase_Level) AS 'Count per Level'
	FROM purchase$
	GROUP BY Purchase_Level