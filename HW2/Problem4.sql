SELECT
  c.name AS "chef name",
  AVG(f.price) AS "average food price"
FROM
  chefs AS c, foods AS f
WHERE
  (f.type = 'Italian' AND c.name = 'John Doe')
  OR (f.type = 'Mexican' AND c.name = 'Alice Johnson')
  OR (f.type = 'French' AND c.name = 'Robert Brown')
  OR (f.type = 'Thai' AND c.name = 'Emily Davis')
  OR (f.type = 'Indian' AND c.name = 'Michael Wilson')
  OR (f.type IN ('Rice', 'Seafood') AND c.name = 'Jane Smith')
GROUP BY
  c.name;