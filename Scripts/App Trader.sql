
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
	
ORDER BY total_income DESC --, sum_total_review_count DESC
LIMIT 152
