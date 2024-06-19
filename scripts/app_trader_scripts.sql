-- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps that the company should target.

-- price range - most are free or 2.99
-- SELECT
-- 	-- a.price AS app_price,
-- 	p.price AS play_price,
-- 	COUNT(*)
-- FROM app_store_apps a
-- JOIN play_store_apps p
-- 	ON a.name = p.name
-- GROUP BY 1
-- ORDER BY 2 DESC, 1 ASC

-- genre 
-- SELECT
-- 	a.primary_genre,
-- 	-- p.genres,
-- 	COUNT(*)
-- FROM app_store_apps a
-- JOIN play_store_apps p
-- 	ON a.name = p.name
-- GROUP BY 1
-- ORDER BY 2 DESC, 1 ASC



-- SELECT
-- 	name,
-- 	CASE
-- 		WHEN a.price > CAST(TRIM('$' FROM p.price) AS numeric) THEN a.price
-- 		WHEN CAST(TRIM('$' FROM p.price) AS numeric) > a.price THEN CAST(TRIM('$' FROM p.price) AS numeric)
-- 		WHEN a.price = CAST(TRIM('$' FROM p.price) AS numeric) THEN a.price
-- 		ELSE 123456789
-- 	END AS max_price 
-- FROM app_store_apps AS a
-- FULL JOIN play_store_apps AS p
-- 	-- ON a.name = p.name
-- 	USING(name)
-- ORDER BY 2 DESC
	
--Haylie's code:
SELECT 
	name, 
	MAX(maxprice)
FROM (
	SELECT name, price AS maxprice
	FROM app_store_apps AS asa
	UNION
	SELECT name, CAST(TRIM('$' from price) AS numeric) AS maxprice
	FROM play_store_apps AS psa
	) AS subquery
GROUP BY name

-- SELECT
-- 	CAST(TRIM('$' FROM p.price) AS numeric) + a.price
-- FROM app_store_apps AS a
-- JOIN play_store_apps AS p
-- USING(name)


-- SELECT
--     CAST(REPLACE(REPLACE(TRIM(p.price), '$', ''), ',', '') AS numeric) + CAST(REPLACE(REPLACE(TRIM(a.price), '$', ''), ',', '') AS numeric) AS total_price
-- FROM app_store_apps AS a
-- JOIN play_store_apps AS p
-- USING(name);

	


	
	
-- FROM app_store_apps a
-- FULL JOIN play_store_apps p
-- 	ON a.name = p.name


-- Select 
-- 	name, 
-- 	-- COALESCE(ROUND(AVG((PLAY.rating + APP.rating)/2), 2), 0) as combined_rating,
-- 	CASE
-- 		WHEN APP.name IS NOT NULL AND THEN APP.rating
-- 		WHEN PLAY.name != 0 THEN PLAY.rating
	
-- FROM app_store_apps APP
-- FULL JOIN play_store_apps PLAY
-- USING(name)
-- GROUP BY name
-- ORDER BY combined_rating DESC




-- b. Develop a Top 10 List of the apps that App Trader should buy.




-- c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may export query results to create charts in Excel for your report. 






