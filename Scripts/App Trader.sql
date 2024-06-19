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
