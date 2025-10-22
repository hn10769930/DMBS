-- List names and sellers of products that are no longer available (quantity=0)
SELECT
    p.name AS product_name,
    m.name AS seller_name
FROM
    products p
JOIN
    sell s ON p.pid = s.pid
JOIN
    merchants m ON s.mid = m.mid
-- Filter for products where the quantity available is 0
WHERE
    s.quantity_available = 0;

-- List names and descriptions of products that are not sold.
SELECT
    p.name,
    p.description
FROM
    products p
-- Use a LEFT JOIN with the 'sell' relation to include all products
LEFT JOIN
    sell s ON p.pid = s.pid
-- Filter for products where there is no matching entry in the 'sell' table
-- thus s.mid will be NULL
WHERE
    s.mid IS NULL;

-- How many customers bought SATA drives but not any routers?
SELECT
    COUNT(DISTINCT cid)
FROM
    customers c
JOIN
    place pl ON c.cid = pl.cid
JOIN
    contain co ON pl.oid = co.oid
JOIN
    products p ON co.pid = p.pid
-- Filter for customers who bought products with 'SATA' in the name or description
WHERE
    (p.name LIKE '%SATA%' OR p.description LIKE '%SATA%')
AND c.cid NOT IN (
    -- Subquery to find the IDs of customers who bought a Router
    SELECT
        pl2.cid
    FROM
        place pl2
    JOIN
        contain co2 ON pl2.oid = co2.oid
    JOIN
        products p2 ON co2.pid = p2.pid
    WHERE
        p2.name LIKE '%Router%' OR p2.description LIKE '%Router%'
);

-- HP has a 20% sale on all its Networking products.
UPDATE
    sell
SET
    price = price * 0.80
-- Join with 'merchants' and 'products' to filter the rows to be updated
WHERE
    (mid, pid) IN (
        SELECT
            m.mid,
            p.pid
        FROM
            merchants m
        JOIN
            products p
        ON
            p.category = 'Networking'
        WHERE
            m.name = 'HP'
    );
    
-- What did Uriel Whitney order from Acer? 
SELECT
    p.name AS product_name,
    s.price AS current_price_sold_by_acer
FROM
    customers c
JOIN
    place pl ON c.cid = pl.cid
JOIN
    contain co ON pl.oid = co.oid
JOIN
    products p ON co.pid = p.pid
JOIN
    sell s ON p.pid = s.pid
JOIN
    merchants m ON s.mid = m.mid
-- Filter for customer 'Uriel Whitney' and merchant 'Acer'
WHERE
    c.fullname = 'Uriel Whitney'
    AND m.name = 'Acer';

-- List the annual total sales for each company
SELECT
    m.name AS company_name,
    STRFTIME('%Y', pl.order_date) AS order_year,
    SUM(s.price) AS annual_total_sales
FROM
    merchants m
JOIN
    sell s ON m.mid = s.mid
JOIN
    contain co ON s.pid = co.pid
JOIN
    place pl ON co.oid = pl.oid
GROUP BY
    m.name,
    order_year
ORDER BY
    company_name,
    order_year;

-- Which company had the highest annual revenue and in what year?
SELECT
    company_name,
    order_year,
    annual_total_sales
FROM
    (
        -- Subquery (aliased as 'AnnualSales') calculates the annual total sales per company
        SELECT
            m.name AS company_name,
            STRFTIME('%Y', pl.order_date) AS order_year,
            SUM(s.price) AS annual_total_sales
        FROM
            merchants m
        JOIN
            sell s ON m.mid = s.mid
        JOIN
            contain co ON s.pid = co.pid
        JOIN
            place pl ON co.oid = pl.oid
        GROUP BY
            m.name,
            order_year
    ) AS AnnualSales
ORDER BY
    annual_total_sales DESC
-- Limit the result to the single highest entry
LIMIT 1;

-- On average, what was the cheapest shipping method used ever?
SELECT
    shipping_method,
    AVG(shipping_cost) AS average_cost
FROM
    orders
GROUP BY
    shipping_method
ORDER BY
    average_cost ASC
-- Limit the result to the one with the lowest average cost
LIMIT 1;

-- What is the best sold ($) category for each company?
SELECT
    t1.name AS company_name,
    t1.category,
    t1.category_revenue
FROM
    (
        -- Subquery to calculate the total revenue per company per category
        SELECT
            m.name,
            p.category,
            SUM(s.price) AS category_revenue,
            -- Use a window function to rank categories by revenue within each company
            ROW_NUMBER() OVER (PARTITION BY m.mid ORDER BY SUM(s.price) DESC) as rn
        FROM
            merchants m
        JOIN
            sell s ON m.mid = s.mid
        JOIN
            products p ON s.pid = p.pid
        GROUP BY
            m.mid, m.name, p.category
    ) AS t1
-- Filter for the rank 1 entry (highest revenue) for each company
WHERE
    t1.rn = 1;

-- For each company find out which customers have spent the most and the least amounts.
WITH CustomerSpending AS (
    -- Calculate total spending by each customer on products sold by each merchant
    SELECT
        m.mid,
        m.name AS company_name,
        c.cid,
        c.fullname AS customer_name,
        SUM(s.price) AS total_spent
    FROM
        merchants m
    JOIN
        sell s ON m.mid = s.mid
    JOIN
        contain co ON s.pid = co.pid
    JOIN
        place pl ON co.oid = pl.oid
    JOIN
        customers c ON pl.cid = c.cid
    GROUP BY
        m.mid, m.name, c.cid, c.fullname
)
, RankedSpending AS (
    -- Rank customers' spending for each company
    SELECT
        company_name,
        customer_name,
        total_spent,
        -- Rank for Most Spent (Highest total_spent)
        ROW_NUMBER() OVER (PARTITION BY mid ORDER BY total_spent DESC) AS rn_most,
        -- Rank for Least Spent (Lowest total_spent)
        ROW_NUMBER() OVER (PARTITION BY mid ORDER BY total_spent ASC) AS rn_least
    FROM
        CustomerSpending
)
-- Select the most and least spending customers for each company
(
    -- MOST SPENT Customer
    SELECT
        company_name,
        'Most Spent' AS spending_type,
        customer_name,
        total_spent
    FROM
        RankedSpending
    WHERE
        rn_most = 1
)
UNION ALL
(
    -- LEAST SPENT Customer
    SELECT
        company_name,
        'Least Spent' AS spending_type,
        customer_name,
        total_spent
    FROM
        RankedSpending
    WHERE
        rn_least = 1
);