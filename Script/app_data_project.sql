-- SELECT psa.name, asa.price, psa.price
-- FROM play_store_apps AS psa
-- INNER JOIN app_store_apps AS asa
-- on psa.name = asa.name

-- CASE WHEN maxprice < 1 THEN 10000
-- 	WHEN maxprice > 1 THEN maxprice * 10000
-- 	ELSE 0

-- WITH maxprice AS
	SELECT name, MAX(maxprice) AS max_price
	FROM (
		SELECT name, price AS maxprice
		FROM app_store_apps AS asa
		UNION
		SELECT name, CAST(TRIM('$' from price) AS numeric) AS maxprice
		FROM play_store_apps AS psa
		) AS subquery
	GROUP BY name
-- SELECT 
-- 	CASE WHEN max_price < 1 THEN 10000
-- 	WHEN max_price > 1 THEN maxprice * 10000
-- 	ELSE 0
-- FROM maxprice

	
