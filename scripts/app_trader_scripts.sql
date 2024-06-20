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


-- couldn't get this to work
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
	



WITH 
subquery1 AS (  -- calculates max_price, avg_rating, monthly_revenue, and app store availability
	SELECT
	      COALESCE(a.name, p.name) AS app_name -- returns the first non null value, so either name is fine since they are the same 
		, GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))::MONEY AS max_price -- returns whichever price is greater  
		, CASE -- returns avg rating when rating in both tables, or rating when in one table 
			WHEN (a.rating IS NULL AND p.rating IS NOT NULL) THEN p.rating -- do we actually need to round all these? The math still holds..
			WHEN (p.rating IS NULL AND a.rating IS NOT NULL) THEN a.rating 
			WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN ROUND((a.rating + p.rating)/2, 1)
			ELSE 0
			END AS avg_rating
		, CASE -- returns 5k revenue when on one store and 10k when on both stores 
			WHEN (a.name IS NULL AND p.name IS NOT NULL) THEN 5000::MONEY
			WHEN (p.name IS NULL AND a.name IS NOT NULL) THEN 5000::MONEY
			WHEN (a.name IS NOT NULL AND p.name IS NOT NULL) THEN 10000::MONEY
			ELSE NULL
			END AS monthly_revenue
		, CASE -- returns which stores the app is available on 
			WHEN (a.name IS NULL AND p.name IS NOT NULL) THEN 'PLAY store only'
			WHEN (p.name IS NULL AND a.name IS NOT NULL) THEN 'APP store only'
			WHEN (a.name = p.name) THEN 'both'
			ELSE NULL
			END AS app_availability
	FROM app_store_apps a
	FULL JOIN play_store_apps p 
		ON a.name = p.name
	),
subquery2 AS (  -- calculates purchase_price (by building on max_price), projected_lifespan (by building on avg_rating), monthly_income (by building on monthly_revenue). 
	SELECT
		app_name
		, CASE -- calculates purchase price 
			WHEN max_price <= 1::MONEY THEN 10000::MONEY
			ELSE (max_price * 10000)::MONEY
	 		END AS purchase_price
		, (avg_rating * 2) + 1 AS projected_lifespan
		, monthly_revenue - 1000::MONEY AS monthly_income  -- is the math right here?? 
	FROM app_store_apps a
	FULL JOIN play_store_apps p 
		ON a.name = p.name
	FULL JOIN subquery1 s1
		ON a.name = s1.app_name
	)
SELECT
      DISTINCT s2.app_name
	, app_availability
	, max_price
	, avg_rating
	, projected_lifespan
	, purchase_price
	, monthly_revenue
	, monthly_income
	, monthly_income * projected_lifespan - purchase_price AS total_income -- is this math correct? 
FROM subquery1 AS s1
FULL JOIN subquery2 AS s2 
	ON s1.app_name = s2.app_name
--WHERE app_availability = 'PLAY store only'
ORDER BY total_income DESC


-- sean's code: 
-- WITH data_list AS
-- 	(SELECT
-- 		name
-- 		,CASE
-- 				WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN 2
-- 				ELSE 1 END AS number_stores
-- 		,CASE
-- 				WHEN (a.rating IS NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(p.rating * 2) / 2, 1)
-- 				WHEN (p.rating IS NULL AND a.rating IS NOT NULL) THEN ROUND(ROUND(a.rating * 2) / 2, 1)
-- 				WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(((a.rating+p.rating)/2) * 2) / 2, 1)
-- 				ELSE '0'
-- 				END AS avg_rating
-- 		,CASE
-- 				WHEN (a.rating IS NULL AND p.rating IS NOT NULL) THEN ((ROUND(ROUND(p.rating * 2) / 2, 1)) + .5) * 2
-- 				WHEN (p.rating IS NULL AND a.rating IS NOT NULL) THEN ((ROUND(ROUND(a.rating * 2) / 2, 1)) + .5) * 2
-- 				WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN ((ROUND(ROUND(((a.rating+p.rating)/2) * 2) / 2, 1))+.5) * 2
-- 				ELSE '1'
-- 				END AS lifespan_years
-- 		,GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))::MONEY AS app_price
-- 		,CASE
-- 				WHEN GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric)) = 0 THEN (GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))+1 * 10000)::MONEY
-- 				ELSE (GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))* 10000)::MONEY END AS purchase_price
-- 	FROM app_store_apps a
-- 	FULL JOIN play_store_apps p
-- 	USING(name)
-- 	)
-- SELECT *
-- 	, (lifespan_years * 12000)::MONEY AS lifespan_marketing_cost
-- 	, ((lifespan_years * 60000)* number_stores)::MONEY AS lifespan_revenue
-- 	, ((lifespan_years * 60000)* number_stores)::MONEY - (lifespan_years * 12000)::MONEY AS lifespan_profit
-- FROM data_list
-- ORDER BY lifespan_profit DESC







-- old code..
-- WITH subquery1 AS (  -- subquery does calculations so main query can call on them 
-- 	SELECT
-- 	    COALESCE(a.name, p.name) AS app_name -- returns the first non null value, so either name is fine since they are the same 
-- 	    , GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric)) AS max_price -- returns largest value from set  
-- 		, CASE -- returns avg rating when rating in both tables, or rating when in one table 
-- 			WHEN (a.rating IS NULL AND p.rating IS NOT NULL) THEN p.rating
-- 			WHEN (p.rating IS NULL AND a.rating IS NOT NULL) THEN a.rating
-- 			WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN ROUND((a.rating + p.rating)/2,1)
-- 			ELSE NULL
-- 			END AS avg_rating 	
-- 		, CASE -- returns 5k revenue when on one store and 10k when on both stores 
-- 			WHEN (a.name IS NULL AND p.name IS NOT NULL) THEN 5000::MONEY
-- 			WHEN (p.name IS NULL AND a.name IS NOT NULL) THEN 5000::MONEY
-- 			WHEN (a.name IS NOT NULL AND p.name IS NOT NULL) THEN 10000::MONEY
-- 			ELSE NULL
-- 			END AS monthly_revenue
-- 	FROM app_store_apps a
-- 	FULL JOIN play_store_apps p 
-- 	ON a.name = p.name
-- 	)
-- SELECT
--     app_name
-- 	, max_price
-- 	, avg_rating
-- 	, (max_price * 10000)::MONEY AS purchase_price
-- 	, monthly_revenue
-- FROM subquery1 AS s1
-- ORDER BY 2 DESC



-- simple code to test 
-- SELECT
-- 	COALESCE(a.name, p.name) as ap_name,
-- 	*
-- 	-- CAST(TRIM('$' FROM p.price) AS numeric) + a.price
-- FROM app_store_apps AS a
-- FULL OUTER JOIN play_store_apps AS p
-- 	ON a.name = p.name
-- WHERE p.name = 'Eu Sou Rico'






-- b. Develop a Top 10 List of the apps that App Trader should buy.




-- c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may export query results to create charts in Excel for your report. 






