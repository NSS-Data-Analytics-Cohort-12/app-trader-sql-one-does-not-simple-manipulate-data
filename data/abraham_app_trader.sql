 -- f. Verify that you have two tables:  
--     - `app_store_apps` with 7197 rows  
--     - `play_store_apps` with 10840 rows

-- #### 2. Assumptions

-- Based on research completed prior to launching App Trader as a company, you can assume the following:

-- a. App Trader will purchase apps for 10,000 times the price of the app. For apps that are priced from free up to $1.00, the purchase price is $10,000.
    
-- - For example, an app that costs $2.00 will be purchased for $20,000.
    
-- - The cost of an app is not affected by how many app stores it is on. A $1.00 app on the Apple app store will cost the same as a $1.00 app on both stores. 
    
-- - If an app is on both stores, it's purchase price will be calculated based off of the highest app price between the two stores. 

-- b. Apps earn $5000 per month, per app store it is on, from in-app advertising and in-app purchases, regardless of the price of the app.
    
-- - An app that costs $200,000 will make the same per month as an app that costs $1.00. 

-- - An app that is on both app stores will make $10,000 per month. 

-- c. App Trader will spend an average of $1000 per month to market an app regardless of the price of the app. If App Trader owns rights to the app in both stores, it can market the app for both stores for a single cost of $1000 per month.
    
-- - An app that costs $200,000 and an app that costs $1.00 will both cost $1000 a month for marketing, regardless of the number of stores it is in.

-- d. For every half point that an app gains in rating, its projected lifespan increases by one year. In other words, an app with a rating of 0 can be expected to be in use for 1 year, an app with a rating of 1.0 can be expected to last 3 years, and an app with a rating of 4.0 can be expected to last 9 years.
    
-- - App store ratings should be calculated by taking the average of the scores from both app stores and rounding to the nearest 0.5.

-- e. App Trader would prefer to work with apps that are available in both the App Store and the Play Store since they can market both for the same $1000 per month.


-- #### 3. Deliverables

-- a. Develop some general recommendations as to the price range, genre, content rating, or anything else for apps that the company should target.

-- b. Develop a Top 10 List of the apps that App Trader should buy.

-- c. Submit a report based on your findings. All analysis work must be done using PostgreSQL, however you may export query results to create charts in Excel for your report. 

-- updated 2/18/2023

--Sean's query:
-- WITH data_list AS
-- 	(SELECT
-- 		DISTINCT name
-- 		,CASE
-- 				WHEN (a.name IS NOT NULL AND p.name IS NOT NULL) THEN 2
-- 					ELSE 1 
-- 					END AS number_stores
-- 		,CASE
-- 				WHEN (a.rating IS NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(p.rating * 2) / 2, 1)
-- 				WHEN (p.rating IS NULL AND a.rating IS NOT NULL) THEN ROUND(ROUND(a.rating * 2) / 2, 1)
-- 				WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(((a.rating+p.rating)/2) * 2) / 2, 1)
-- 					ELSE '0'
-- 					END AS avg_rating
-- 		,CASE
-- 				WHEN (a.rating IS NULL AND p.rating IS NOT NULL) THEN ((ROUND(ROUND(p.rating * 2) / 2, 1)) + .5) * 2
-- 				WHEN (p.rating IS NULL AND a.rating IS NOT NULL) THEN ((ROUND(ROUND(a.rating * 2) / 2, 1)) + .5) * 2
-- 				WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN ((ROUND(ROUND(((a.rating+p.rating)/2) * 2) / 2, 1))+.5) * 2
-- 					ELSE '1'
-- 					END AS lifespan_years
-- 		,GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))::MONEY AS app_price
-- 		,CASE
-- 				WHEN GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric)) <= 1 THEN 10000::MONEY
-- 				ELSE (GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))* 10000)::MONEY END AS purchase_price
-- 	FROM app_store_apps a
-- 	FULL JOIN play_store_apps p
-- 	USING(name)
-- 	)
-- SELECT *
-- 	, (lifespan_years * 12000)::MONEY AS lifespan_marketing_cost
-- 	, ((lifespan_years * 60000)* number_stores)::MONEY AS lifespan_revenue
-- FROM data_list
-- WHERE number_stores = 2
-- 	AND avg_rating >= 4
-- ORDER BY lifespan_revenue DESC

--Ryan's Query:
-- WITH
-- subquery1 AS (  -- calculates max_price, avg_rating, monthly_revenue, and app store availability
-- 	SELECT
-- 	      COALESCE(a.name, p.name) AS app_name -- returns the first non null value, so either name is fine since they are the same
-- 		, GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))::MONEY AS max_price -- returns whichever price is greater
-- 		, CASE -- returns avg rating when rating in both tables, or rating when in one table
-- 			WHEN (a.rating IS NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(p.rating * 2) / 2, 1)
-- 			WHEN (p.rating IS NULL AND a.rating IS NOT NULL) THEN ROUND(ROUND(a.rating * 2) / 2, 1)
-- 			WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(((a.rating+p.rating)/2) * 2) / 2, 1)
-- 			ELSE 0
-- 			END AS avg_rating
-- 		, CASE -- returns 5k revenue when on one store and 10k when on both stores
-- 			WHEN (a.name IS NULL AND p.name IS NOT NULL) THEN 5000::MONEY
-- 			WHEN (p.name IS NULL AND a.name IS NOT NULL) THEN 5000::MONEY
-- 			WHEN (a.name IS NOT NULL AND p.name IS NOT NULL) THEN 10000::MONEY
-- 			ELSE NULL
-- 			END AS monthly_revenue
-- 		, CASE -- returns which stores the app is available on
-- 			WHEN (a.name IS NULL AND p.name IS NOT NULL) THEN 'PLAY store only'
-- 			WHEN (p.name IS NULL AND a.name IS NOT NULL) THEN 'APP store only'
-- 			WHEN (a.name = p.name) THEN 'both'
-- 			ELSE NULL
-- 			END AS app_availability
-- 	FROM app_store_apps a
-- 	FULL JOIN play_store_apps p
-- 		ON a.name = p.name
-- 	),
-- subquery2 AS (  -- calculates purchase_price (by building on max_price), projected_lifespan (by building on avg_rating), monthly_income (by building on monthly_revenue).
-- 	SELECT
-- 		app_name
-- 		, CASE -- calculates purchase price
-- 			WHEN max_price <= 1::MONEY THEN 10000::MONEY
-- 			ELSE (max_price * 10000)::MONEY
-- 	 		END AS purchase_price
-- 		, (avg_rating * 2) + 1 AS projected_lifespan
-- 		, monthly_revenue - 1000::MONEY AS monthly_income  -- is the math right here??
-- 	FROM app_store_apps a
-- 	FULL JOIN play_store_apps p
-- 		ON a.name = p.name
-- 	FULL JOIN subquery1 s1
-- 		ON a.name = s1.app_name
-- 	)
-- SELECT
--       DISTINCT s2.app_name
-- 	, app_availability
-- 	, max_price
-- 	, avg_rating
-- 	, projected_lifespan
-- 	, purchase_price
-- 	, monthly_revenue
-- 	, monthly_income
-- 	, monthly_income*12 * projected_lifespan - purchase_price AS total_income -- is this math correct?
-- FROM subquery1 AS s1
-- FULL JOIN subquery2 AS s2
-- 	ON s1.app_name = s2.app_name
-- WHERE s2.app_name IS NOT NULL
-- ORDER BY total_income DESC
-- LIMIT 152

-- SELECT
-- 	DISTINCT COALESCE(a.name, p.name) as ap_name,
-- 	CAST(a.review_count AS integer),
-- 	p.review_count AS play_review,
-- 	CAST(a.review_count AS integer) + p.review_count AS combined_review_count
-- 	-- CAST(TRIM('$' FROM p.price) AS numeric) + a.price
-- FROM app_store_apps AS a
-- FULL OUTER JOIN play_store_apps AS p
-- 	ON a.name = p.name
-- --WHERE p.name = 'Eu Sou Rico'
-- WHERE a.rating IS NOT NULL AND CAST(a.review_count AS integer) + p.review_count IS NOT NULL
-- ORDER BY combined_review_count DESC

--Ryan's updated query at 8:17
-- WITH
-- subquery1 AS (  -- calculates max_price, avg_rating, monthly_revenue, and app store availability
-- 	SELECT
-- 	      COALESCE(a.name, p.name) AS app_name -- returns the first non null value, so either name is fine since they are the same
-- 		, GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))::MONEY AS max_price -- returns whichever price is greater
-- 		, CASE -- returns avg rating when rating in both tables, or rating when in one table
-- 			WHEN (a.rating IS NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(p.rating * 2) / 2, 1)
-- 			WHEN (p.rating IS NULL AND a.rating IS NOT NULL) THEN ROUND(ROUND(a.rating * 2) / 2, 1)
-- 			WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(((a.rating+p.rating)/2) * 2) / 2, 1)
-- 			ELSE 0
-- 			END AS avg_rating
-- 		, CASE -- returns 5k revenue when on one store and 10k when on both stores
-- 			WHEN (a.name IS NULL AND p.name IS NOT NULL) THEN 5000::MONEY
-- 			WHEN (p.name IS NULL AND a.name IS NOT NULL) THEN 5000::MONEY
-- 			WHEN (a.name IS NOT NULL AND p.name IS NOT NULL) THEN 10000::MONEY
-- 			ELSE NULL
-- 			END AS monthly_revenue
-- 		, CASE -- returns which stores the app is available on
-- 			WHEN (a.name IS NULL AND p.name IS NOT NULL) THEN 'PLAY store only'
-- 			WHEN (p.name IS NULL AND a.name IS NOT NULL) THEN 'APP store only'
-- 			WHEN (a.name = p.name) THEN 'both'
-- 			ELSE NULL
-- 			END AS app_availability
-- 	FROM app_store_apps a
-- 	FULL JOIN play_store_apps p
-- 		ON a.name = p.name
-- 	),
-- subquery2 AS (  -- calculates purchase_price (by building on max_price), projected_lifespan (by building on avg_rating), monthly_income (by building on monthly_revenue).
-- 	SELECT
-- 		app_name
-- 		, CASE -- calculates purchase price
-- 			WHEN max_price <= 1::MONEY THEN 10000::MONEY
-- 			ELSE (max_price * 10000)::MONEY
-- 	 		END AS purchase_price
-- 		, (avg_rating * 2) + 1 AS projected_lifespan
-- 		, monthly_revenue - 1000::MONEY AS monthly_income  -- is the math right here??
-- 		, GREATEST(CAST(a.review_count AS integer), p.review_count) AS total_review_count
-- 	FROM app_store_apps a
-- 	FULL JOIN play_store_apps p
-- 		ON a.name = p.name
-- 	FULL JOIN subquery1 s1
-- 		ON a.name = s1.app_name
-- 	)
-- SELECT
--       DISTINCT (s2.app_name)
-- 	, app_availability
-- 	, max_price
-- 	, avg_rating
-- 	, projected_lifespan
-- 	, purchase_price
-- 	, monthly_revenue
-- 	, monthly_income
-- 	, monthly_income*12 * projected_lifespan - purchase_price AS total_income
-- 	-- , SUM(total_review_count) OVER(PARTITION BY s2.app_name) AS sum_total_review_count
--  	--, total_review_count
-- FROM subquery1 AS s1
-- FULL JOIN subquery2 AS s2
-- 	ON s1.app_name = s2.app_name
-- WHERE s2.app_name IS NOT NULL
-- 	AND total_review_count IS NOT NULL
-- 	-- AND s2.app_name = 'Instagram'
-- ORDER BY total_income DESC ;, --sum_total_review_count DESC
-- --LIMIT 152

-- Ryan's Updated Query
WITH
subquery1 AS (  -- calculates max_price, avg_rating, monthly_revenue, and app store availability
	SELECT
	      DISTINCT COALESCE(a.name, p.name) AS app_name -- returns the first non null value, so either name is fine since they are the same
		, GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))::MONEY AS max_price -- returns whichever price is greater
		, CASE -- returns avg rating when rating in both tables, or rating when in one table
			WHEN (a.rating IS NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(p.rating * 2) / 2, 1)
			WHEN (p.rating IS NULL AND a.rating IS NOT NULL) THEN ROUND(ROUND(a.rating * 2) / 2, 1)
			WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(((a.rating+p.rating)/2) * 2) / 2, 1)
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
		DISTINCT app_name
		, CASE -- calculates purchase price
			WHEN max_price <= 1::MONEY THEN 10000::MONEY
			ELSE (max_price * 10000)::MONEY
	 		END AS purchase_price
		, (avg_rating * 2) + 1 AS projected_lifespan
		, monthly_revenue - 1000::MONEY AS monthly_income  -- is the math right here??
		, CAST(a.review_count AS integer) + p.review_count AS total_review_count
	FROM app_store_apps a
	FULL JOIN play_store_apps p
		ON a.name = p.name
	FULL JOIN subquery1 s1
		ON a.name = s1.app_name
	)
SELECT
      DISTINCT (s2.app_name)
	, app_availability
	, max_price
	, avg_rating
	, projected_lifespan
	, purchase_price
	, monthly_revenue
	, monthly_income
	, monthly_income*12 * projected_lifespan - purchase_price AS total_income
	, SUM(total_review_count) OVER(PARTITION BY s2.app_name) AS sum_total_review_count
 	--, total_review_count
FROM subquery1 AS s1
FULL JOIN subquery2 AS s2
	ON s1.app_name = s2.app_name
WHERE s2.app_name IS NOT NULL
	AND total_review_count IS NOT NULL
	-- AND s2.app_name = 'Instagram'
ORDER BY total_income DESC --, sum_total_review_count DESC
LIMIT 152