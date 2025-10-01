SELECT
  r.name AS "restaurant name",
  AVG(f.price) AS "average food price"
FROM
  restaurants AS r, foods AS f
WHERE
  (f.type = 'Italian' AND r.name = 'La Trattoria')
  OR (f.type = 'Mexican' AND r.name = 'Taco Town')
  OR (f.type = 'French' AND r.name = 'Bistro Paris')
  OR (f.type = 'Thai' AND r.name = 'Thai Delight')
  OR (f.type = 'Indian' AND r.name = 'Indian Spice')
  OR (f.type IN ('Rice', 'Seafood') AND r.name = 'Sushi Haven')
GROUP BY
  r.name
ORDER BY
  "average food price" DESC
LIMIT 1;