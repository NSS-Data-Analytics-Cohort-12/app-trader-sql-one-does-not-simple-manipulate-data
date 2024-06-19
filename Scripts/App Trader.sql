WITH data_list AS
	(SELECT
		DISTINCT name
		,CASE
				WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN 2
				ELSE 1 END AS number_stores
		,CASE 
				WHEN (a.rating IS NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(p.rating * 2) / 2, 1)
				WHEN (p.rating IS NULL AND a.rating IS NOT NULL) THEN ROUND(ROUND(a.rating * 2) / 2, 1)
				WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN ROUND(ROUND(((a.rating+p.rating)/2) * 2) / 2, 1)
				ELSE '0'
				END AS avg_rating
		,CASE 
				WHEN (a.rating IS NULL AND p.rating IS NOT NULL) THEN ((ROUND(ROUND(p.rating * 2) / 2, 1)) + .5) * 2
				WHEN (p.rating IS NULL AND a.rating IS NOT NULL) THEN ((ROUND(ROUND(a.rating * 2) / 2, 1)) + .5) * 2
				WHEN (a.rating IS NOT NULL AND p.rating IS NOT NULL) THEN ((ROUND(ROUND(((a.rating+p.rating)/2) * 2) / 2, 1))+.5) * 2
				ELSE '1'
				END AS lifespan_years
		,GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))::MONEY AS app_price
		,CASE
				WHEN GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric)) = 0 THEN (GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))+1 * 10000)::MONEY
				ELSE (GREATEST(a.price, CAST(TRIM('$' FROM p.price) AS numeric))* 10000)::MONEY END AS purchase_price
	FROM app_store_apps a
	FULL JOIN play_store_apps p 
	USING(name) 
	)
SELECT  *
	, (lifespan_years * 12000)::MONEY AS lifespan_marketing_cost
	, ((lifespan_years * 60000)* number_stores)::MONEY AS lifespan_revenue
FROM data_list
WHERE number_stores = 2
	AND avg_rating >= 4
ORDER BY lifespan_revenue DESC