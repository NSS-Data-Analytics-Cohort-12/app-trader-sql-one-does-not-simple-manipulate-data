Select name, ROUND(AVG((PLAY.rating + APP.rating)/2), 5) as combined_rating
FROM app_store_apps APP
LEFT JOIN play_store_apps PLAY
USING(name)
GROUP BY name
ORDER BY combined_rating DESC