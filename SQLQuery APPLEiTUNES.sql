USE [APPLE iTUNES Analysis];

SELECT * FROM track
SELECT* FROM playlist_track
SELECT * FROM playlist
SELECT * FROM media_type
SELECT * FROM invoice_line
SELECT * FROM genre
SELECT * FROM employee
--Q1. Who is the senior most employee based on job title?
SELECT employee_id,first_name,last_name
	FROM employee
	WHERE reports_to IS NULL;

	
SELECT * FROM customer
SELECT * FROM artist
SELECT * FROM album
SELECT * FROM invoice

--Q2. Which countries have the most Invoices?

SELECT top 10 billing_country,
	   COUNT(invoice_id)AS invoice_count
FROM invoice
GROUP BY billing_country
ORDER BY invoice_count DESC;
SELECT top 3 total_invoice_amount
FROM invoice
ORDER BY total_invoice_amount DESC;



--Q3. What are top 3 values of total invoice?
SELECT top 3 total_invoice_amount,
		ROUND(total_invoice_amount,2) AS rounded_total
FROM invoice
ORDER BY total_invoice_amount DESC;

--Q4. Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
--     Write a query that returns one city that has the highest sum of invoice totals.
--Return both the city name & sum of all invoice totals.
SELECT TOP 1
    billing_city,
    SUM(total_invoice_amount) AS total_sales
FROM invoice
GROUP BY billing_city
ORDER BY total_sales DESC;

--Q5. Who is the best customer? The customer who has spent the most money will be declared the best customer. 
SELECT TOP 1
    c.customer_id,
    c.first_name,
    c.last_name,
    SUM(total_invoice_amount) AS total_spent
FROM customer AS c
INNER JOIN invoice AS i
    ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;

--Q6. Write a query to return the email, first name, last name, & Genre of all Rock Music listeners.
--Return your list ordered alphabeticallyby email starting with A.

SELECT DISTINCT 
    c.email,
    c.first_name,
    c.last_name,
    g.name AS genre
FROM customer AS c
INNER JOIN invoice AS i
    ON c.customer_id = i.customer_id
INNER JOIN invoice_line AS il
    ON i.invoice_id = il.invoice_id
INNER JOIN track t
    ON il.track_id = t.track_id
INNER JOIN genre g
    ON t.genre_id = g.genre_id
WHERE g.name = 'Rock'
ORDER BY c.email ASC;

--Q7. Let's invite the artists who have written the most rock music in our dataset. 
--     Write a query that returns the Artist name and total track count of the top 10 rock bands.
SELECT 
    ar.name AS artist_name,
    COUNT(t.track_id) AS rock_track_count
FROM track t
INNER JOIN album al
    ON t.album_id = al.album_id
INNER JOIN artist ar
    ON al.artist_id = ar.artist_id
WHERE t.genre_id = 1   -- Rock
GROUP BY ar.name
ORDER BY rock_track_count DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

--Q8. Return all the track names that have a song length longer than the average song length. 
--     Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.
SELECT 
    name AS track_name,
    milliseconds
FROM track
WHERE milliseconds > (
    SELECT AVG(milliseconds) FROM track
)
ORDER BY milliseconds DESC;

--Q9. Find how much amount spent by each customer on artists. Write a query to return the customer name, artist name, and total spent.

SELECT 
    c.first_name,c.last_name AS customer_name,
    ar.name AS artist_name,
    SUM(il.unit_price * il.quantity) AS total_spent
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN artist ar ON al.artist_id = ar.artist_id
GROUP BY c.first_name, c.last_name, ar.name
ORDER BY total_spent DESC;

--Q10. We want to find out the most popular music Genre for each country. 
--      We determine the most popular genre as the genre with the highest amount of purchases. 
--    Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres.

WITH GenrePerCountry AS (
    SELECT 
        c.country,
        g.name AS genre_name,
        COUNT(il.invoice_line_id) AS purchase_count
    FROM customer c
    JOIN invoice i 
        ON c.customer_id = i.customer_id
    JOIN invoice_line il 
        ON i.invoice_id = il.invoice_id
    JOIN track t 
        ON il.track_id = t.track_id
    JOIN genre g 
        ON t.genre_id = g.genre_id
    GROUP BY c.country, g.name
),
MaxGenre AS (
    SELECT 
        country,
        MAX(purchase_count) AS max_purchases
    FROM GenrePerCountry
    GROUP BY country
)
SELECT 
    gp.country,
    gp.genre_name,
    gp.purchase_count
FROM GenrePerCountry gp
JOIN MaxGenre mg
    ON gp.country = mg.country
   AND gp.purchase_count = mg.max_purchases
ORDER BY gp.country, gp.genre_name;

--Q11. Write a query that determines the customer that has spent the most on music for each country. 
--Write a query that returns the country along with the top customer and how much they spent. 
--For countries where the top amount spent is shared, provide all customers who spent this amount.

WITH CustomerSpend AS (
    SELECT 
        c.country,
        c.customer_id,
        c.first_name,
        c.last_name,
        SUM(i.total_invoice_amount) AS total_spent
    FROM customer AS c
    INNER JOIN invoice AS i
        ON c.customer_id = i.customer_id
       AND c.country = i.billing_country
    GROUP BY c.country, c.customer_id, c.first_name, c.last_name
),
MaxSpend AS (
    SELECT 
        country,
        MAX(total_spent) AS max_spent
    FROM CustomerSpend
    GROUP BY country
)
SELECT 
    cs.country,
    cs.customer_id,
    cs.first_name,
    cs.last_name,
    cs.total_spent
FROM CustomerSpend cs
INNER JOIN MaxSpend ms
    ON cs.country = ms.country
   AND cs.total_spent = ms.max_spent
ORDER BY cs.country, cs.total_spent DESC;

--Q12. Who are the most popular artists?
SELECT TOP 10 
    ar.name AS artist_name,
    SUM(il.quantity) AS total_purchases
FROM invoice_line il
JOIN track t 
    ON il.track_id = t.track_id
JOIN album al 
    ON t.album_id = al.album_id
JOIN artist ar 
    ON al.artist_id = ar.artist_id
GROUP BY ar.name
ORDER BY total_purchases DESC;

--Q13. Which is the most popular song?
--•	On the basis of Purchase
SELECT TOP 1
    t.name AS track_name,
    SUM(il.quantity) AS total_purchases
FROM invoice_line il
JOIN track t 
    ON il.track_id = t.track_id
GROUP BY t.name
ORDER BY total_purchases DESC;
--•	On the basis of milliseconds spent
SELECT TOP 1
    t.name AS track_name,
    SUM(t.milliseconds * il.quantity) AS total_listen_time
FROM invoice_line il
JOIN track t 
    ON il.track_id = t.track_id
GROUP BY t.name
ORDER BY total_listen_time DESC;

--Q14. What are the average prices of different types of music?
SELECT 
    g.name AS genre_name,
    ROUND(AVG(t.unit_price), 2) AS avg_price
FROM track t
JOIN genre g 
    ON t.genre_id = g.genre_id
GROUP BY g.name
ORDER BY avg_price DESC;

--Q.15 What are the most popular countries for music purchases?
SELECT 
    billing_country,
    COUNT(invoice_id) AS total_purchases
FROM invoice
GROUP BY billing_country
ORDER BY total_purchases DESC;


