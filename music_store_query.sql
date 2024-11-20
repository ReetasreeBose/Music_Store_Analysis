-- Q1: Who is the senior most employee based on job title? higher level no.=higher seniority
SELECT employee_id, title, first_name || ' ' || last_name AS employee_name, levels FROM employee
ORDER BY levels DESC
LIMIT 1

-- Q2: Which countries have the most Invoices? 
select billing_country, count(*) as number_of_invoices from invoice
group by billing_country
order by number_of_invoices desc

--Q3: What are top 3 values of total invoice?
select total from invoice order by total desc limit 3

--Q4: Which city has the best customers? 
--We would like to throw a promotional Music Festival in the city we made the most money. 
--Write a query that returns one city that has the highest sum of invoice totals. 
--Return both the city name & sum of all invoice totals

select billing_city, sum(total) as invoice_total from invoice
group by billing_city order by invoice_total desc limit 1

-- Q5: Who is the best customer? 
--The customer who has spent the most money will be declared the best customer. 
--Write a query that returns the person who has spent the most money.

select first_name || ' ' || last_name AS customer_name, sum(total) as money_spent
from customer as c inner join invoice as i on c.customer_id = i.customer_id
group by first_name || ' ' || last_name order by money_spent desc limit 1

-- Q6: Write query to return the email, first name, last name of all Rock Music listeners. 
--Return your list ordered alphabetically by email starting with A.

select distinct first_name, last_name, email 
from customer as c inner join invoice as i on c.customer_id = i.customer_id
inner join invoice_line as il on i.invoice_id = il.invoice_id
where track_id in (
	select track_id from track as t
	inner join genre as g on t.genre_id = g.genre_id
	where g.name = 'Rock'
)
order by email asc
--query optimized : above 109msec below 67msec
select distinct first_name, last_name, email 
from customer as c inner join invoice as i on c.customer_id = i.customer_id
inner join invoice_line as il on i.invoice_id = il.invoice_id
inner join track as t on il.track_id = t.track_id
inner join genre as g on t.genre_id = g.genre_id
where g.name = 'Rock'
order by email asc

--Q7: Let's invite the artists who have written the most rock music in our dataset. 
--Write a query that returns the Artist name and total track count of the top 10 rock artists.

select artist.name, count(*) as track_count from artist 
inner join album on artist.artist_id = album.artist_id
inner join track on album.album_id = track.album_id
inner join genre on track.genre_id = genre.genre_id
where genre.name like 'Rock' 
group by artist.name order by track_count desc limit 10

--Q8: Return all the track names that have a song length longer than the average song length. 
--Return the Name and Milliseconds for each track.
--Order by the song length with the longest songs listed first.

select name as track_name, milliseconds as length_of_the_song from track
where milliseconds > (select avg(milliseconds) from track)
order by length_of_the_song desc

--Q9: Find how much amount spent by each customer on top earning artist or best selling artist? 
--Write a query to return customer name, artist name and total spent by customer

with best_selling_artist as (
	select artist.artist_id, artist.name as artist_name, round(sum(il.unit_price::numeric * il.quantity::numeric),2) as total_sales
	from invoice_line as il
	join track on track.track_id = il.track_id
	join album on album.album_id = track.album_id
	join artist on artist.artist_id = album.artist_id
	group by 1,2
	order by total_sales desc limit 1
)
SELECT c.first_name || ' ' || c.last_name as full_name, bsa.artist_name, 
round(sum(il.unit_price::numeric * il.quantity::numeric),2) as amount_spent
from customer as c
join invoice as i on c.customer_id = i.customer_id
join invoice_line as il on il.invoice_id = i.invoice_id
join track as t on t.track_id = il.track_id
join album as alb ON alb.album_id = t.album_id
join best_selling_artist as bsa on bsa.artist_id = alb.artist_id
group by 1,2
order by amount_spent desc;

--Q10: We want to find out the most popular music Genre for each country. 
--We determine the most popular genre as the genre with the highest number of purchases. 
--Write a query that returns each country along with the top Genre. For countries where 
--the maximum number of purchases is shared return all Genres.

with country_wise_genre as	
(select i.billing_country , g.name, count(il.quantity), 
row_number () over(partition by i.billing_country order by count(il.quantity) desc) as rn	
from genre as g
inner join track as t on t.genre_id = g.genre_id
inner join invoice_line as il on t.track_id = il.track_id
inner join invoice as i on il.invoice_id = i.invoice_id
group by i.billing_country , g.name)

select billing_country, name as genre_name from country_wise_genre
where rn = 1

--Q11: Write a query that determines the customer that has spent the most on music for each country. 
--Write a query that returns the country along with the top customer and how much they spent. 
--For countries where the top amount spent is shared, provide all customers who spent this amount.
	
with country_wise_customer_spentamount as
(select c.first_name || ' ' || c.last_name as full_name, c.country, 
round(sum(i.total::numeric),2) as most_spent,
dense_rank() over(partition by c.country order by sum(i.total) desc) as drn
from customer as c inner join invoice as i on c.customer_id = i.customer_id
group by 1,2 order by c.country)
	
select full_name, country, most_spent,drn from country_wise_customer_spentamount
where drn = 1 order by country

