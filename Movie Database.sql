/*
Question Set Number 1:


Question 1:
(Slide 1)
Create a query that lists each movie, the film category it is classified in, and
the number of times it has been rented out.
*/
WITH film_rental_dates AS
    (SELECT f.film_id AS film_id, COUNT(*) AS rental_count
    FROM film f
    JOIN inventory i
    ON f.film_id = i.film_id
    JOIN rental r
    ON i.inventory_id = r.inventory_id
    GROUP BY 1)

SELECT f.title AS film_title, c.name AS category_name, frd.rental_count
FROM film_rental_dates frd
JOIN film f
ON frd.film_id = f.film_id
JOIN film_category fc
ON f.film_id = fc.film_id
JOIN category c
ON c.category_id = fc.category_id
WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
ORDER BY 2, 1;


/*
Question 2:
(Slide 2)
Now we need to know how the length of rental duration of these family-friendly
movies compares to the duration that all movies are rented for. Can you provide
a table with the movie titles and divide them into 4 levels (first_quarter,
second_quarter, third_quarter, and final_quarter) based on the quartiles
(25%, 50%, 75%) of the rental duration for movies across all categories? Make
sure to also indicate the category that these family-friendly movies fall into.
*/
WITH rental_quartiles AS
    (SELECT f.title AS film_title, c.name AS category_name,
      f.rental_duration AS rental_duration,
      NTILE(4) OVER (ORDER BY rental_duration) AS standard_quartile
    FROM film f
    JOIN film_category fc
    ON f.film_id = fc.film_id
    JOIN category c
    ON fc.category_id = c.category_id)

SELECT rq.*
FROM rental_quartiles rq
JOIN film f
ON rq.film_title = f.title
WHERE rq.category_name IN ('Animation', 'Children', 'Classics', 'Comedy',
  'Family', 'Music')
ORDER BY 4, 3, 1;


/*
Question 3:
(Slide 3)
Finally, provide a table with the family-friendly film category, each of the
quartiles, and the corresponding count of movies within each combination of film
category for each corresponding rental duration category. The resulting table
should have three columns:

-Category
-Rental length category
-Count
*/
WITH category_quartiles AS
    (SELECT f.film_id, f.title, c.name AS category_name,
      NTILE(4) OVER (ORDER BY f.rental_duration) AS standard_quartile
    FROM film f
    JOIN film_category fc
    ON f.film_id = fc.film_id
    JOIN category c
    ON fc.category_id = c.category_id
    WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy',
      'Family', 'Music'))

SELECT category_name, standard_quartile, COUNT(*)
FROM category_quartiles
GROUP BY 1, 2
ORDER BY 1, 2;


/*
Question Set Number 2:


Question 1:
(Slide 4)
We want to find out how the two stores compare in their count of rental orders
during every month for all the years we have data for. Write a query that
returns the store ID for the store, the year and month and the number of rental
orders each store has fulfilled for that month. Your table should include a
column for each of the following: year, month, store ID and count of rental
orders fulfilled during that month.
*/
SELECT DATE_PART('month', r.rental_date) AS rental_month,
  DATE_PART('year', r.rental_date) AS rental_year,
  store.store_id,
  COUNT(*) AS count_rentals
FROM store
JOIN staff
ON store.store_id = staff.store_id
JOIN rental r
ON staff.staff_id = r.staff_id
GROUP BY 3, 1, 2
ORDER BY 4 DESC;


/*
Question 2:
(Slide 5)
We would like to know who were our top 10 paying customers, how many payments
they made on a monthly basis during 2007, and what was the amount of the monthly
payments. Can you write a query to capture the customer name, month and year of
payment, and total payment amount for each month by these top 10 paying
customers?
*/
WITH top_10_customers AS
    (SELECT customer_id, SUM(amount) AS pay_amount
    FROM payment
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 10),

    full_name AS
    (SELECT top.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS name
    FROM customer c
    JOIN top_10_customers top
    ON c.customer_id = top.customer_id),

    customer_monthly_amount AS
    (SELECT DATE_TRUNC('month', p.payment_date) AS payment_month,
      top.customer_id,
      COUNT(*) AS num_payments_per_mnth,
      SUM(p.amount) AS pay_amount
    FROM payment p
    JOIN top_10_customers top
    ON top.customer_id = p.customer_id
    GROUP BY 2, 1)

SELECT c.payment_month, f.name, c.num_payments_per_mnth, c.pay_amount
FROM full_name f
JOIN customer_monthly_amount c
ON c.customer_id = f.customer_id
ORDER BY 2, 1;


/*
Question 3:
(Slide 6)
Finally, for each of these top 10 paying customers, I would like to find out the
difference across their monthly payments during 2007. Please go ahead and write
a query to compare the payment amounts in each successive month. Repeat this for
each of these 10 paying customers. Also, it will be tremendously helpful if you
can identify the customer name who paid the most difference in terms of payments.
*/
WITH top_10_customers AS
    (SELECT customer_id, SUM(amount) AS pay_amount
    FROM payment
    GROUP BY 1
    ORDER BY 2 DESC
    LIMIT 10),

    full_name AS
    (SELECT top.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS name
    FROM customer c
    JOIN top_10_customers top
    ON c.customer_id = top.customer_id),

    customer_monthly_amount AS
    (SELECT DATE_TRUNC('month', p.payment_date) AS payment_month,
      top.customer_id,
      COUNT(*) AS num_payments_per_mnth,
      SUM(p.amount) AS pay_amount
    FROM payment p
    JOIN top_10_customers top
    ON top.customer_id = p.customer_id
    GROUP BY 2, 1)

SELECT c.payment_month, f.name, c.num_payments_per_mnth, c.pay_amount,
  COALESCE(LAG(c.pay_amount) OVER (PARTITION BY f.name ORDER BY c.payment_month), 0) AS monthly_lag,
  c.pay_amount - COALESCE(LAG(c.pay_amount) OVER (PARTITION BY f.name ORDER BY c.payment_month), 0) AS lag_difference
FROM full_name f
JOIN customer_monthly_amount c
ON c.customer_id = f.customer_id
ORDER BY 2, 1;
