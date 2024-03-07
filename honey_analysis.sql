use honey; 

-- Display the first 5 rows of the dataset:
SELECT TOP 5 * FROM honey;


-- Get the distinct values of the 'Pollen_analysis' column:
SELECT DISTINCT Pollen_analysis
FROM honey;


-- Display the average price of honey in the dataset:
SELECT AVG(Price) AS Average_Price
FROM honey;


--  Display the maximum and minimum pH values:
SELECT MIN(pH) AS Min_pH, MAX(pH) AS Max_pH
FROM honey;


-- Calculate the average 'Viscosity' for each 'Pollen_analysis' group:
SELECT Pollen_analysis, AVG(CAST(Viscosity AS FLOAT)) AS avg_viscosity
FROM honey
GROUP BY Pollen_analysis;


-- Calculate the average price and purity for each pollen type:
SELECT Pollen_analysis, AVG(CAST(Price AS FLOAT)) AS avg_price, AVG(CAST(Purity AS FLOAT)) AS avg_purity
FROM honey
GROUP BY Pollen_analysis;


-- Filter rows where the price is above the average price:
SELECT *
FROM honey
WHERE CAST(Price AS FLOAT) > (SELECT AVG(CAST(Price AS FLOAT)) FROM honey);


-- Find the rows where both 'Purity' and 'Price' are above their respective averages:
SELECT *
FROM honey
WHERE CAST(Purity AS FLOAT) > (SELECT AVG(CAST(Purity AS FLOAT)) FROM honey)
  AND CAST(Price AS FLOAT) > (SELECT AVG(CAST(Price AS FLOAT)) FROM honey);


-- Retrieve the highest priced honey along with its details:
SELECT TOP 1 *
FROM honey
ORDER BY Price DESC


-- Find the average density for each type of honey, ordered by highest to lowest average density:
SELECT Pollen_analysis, AVG(Density) AS Avg_Density
FROM honey
GROUP BY Pollen_analysis
ORDER BY Avg_Density DESC;


-- Display the average price for honey with a purity greater than 0.8:
SELECT AVG(Price) AS Average_Price
FROM honey
WHERE Purity > 0.8;


-- Calculate the total price for each type of honey:
SELECT Pollen_analysis, SUM(Price) AS Total_Price
FROM honey
GROUP BY Pollen_analysis;


-- Calculate the weighted average purity of honey, considering the price as the weight:
SELECT SUM(Purity * Price) / SUM(Price) AS Weighted_Avg_Purity
FROM honey;


-- Identify the honeys with purity levels significantly different from the average purity, considering a threshold of one standard deviation:
SELECT *
FROM honey
WHERE ABS(Purity - (SELECT AVG(Purity) FROM honey)) > (SELECT STDEV(Purity) FROM honey);


-- Determine the most frequent pollen analysis type:
SELECT TOP 1 Pollen_analysis, COUNT(*) as Count
FROM honey
GROUP BY Pollen_analysis
ORDER BY Count DESC;


-- Identify honey samples with the highest purity levels:
SELECT *
FROM honey
WHERE Purity = 1;


-- What are the purity ranges for each type of pollen analysis in the honey samples?
SELECT
Pollen_analysis,
    Purity,
    CASE
WHEN ROUND(Purity, 2) BETWEEN 0 AND 0.4 THEN 'Low purity (0 - 0.4)'
WHEN ROUND(Purity, 2) BETWEEN 0.41 AND 0.8 THEN 'Medium purity (0.41 - 0.8)'
WHEN ROUND(Purity, 2) BETWEEN 0.81 AND 1 THEN 'High purity (0.81 - 1)'
ELSE 'Invalid purity'
END AS Purity_Range
FROM honey;


-- Display the top 3 types of pollen analysis with the highest average price, along with their standard deviation in price:
SELECT TOP 3
Pollen_analysis,
    AVG(Price) AS Average_Price,
    STDEV(Price) AS Price_StdDev
FROM honey
GROUP BY Pollen_analysis
ORDER BY Average_Price DESC;


-- Find rows where the price is higher than the average price for its pollen type:
SELECT *
FROM honey h1
WHERE CAST(h1.Price AS FLOAT) > (
    SELECT AVG(CAST(h2.Price AS FLOAT))
    FROM honey h2
    WHERE h1.Pollen_analysis = h2.Pollen_analysis
);


-- Get the top 3 highest prices for each 'Pollen_analysis' group:
WITH cte AS (
    SELECT *,
           RANK() OVER (PARTITION BY Pollen_analysis ORDER BY CAST(Price AS FLOAT) DESC) AS rank_price
    FROM honey
)
SELECT Pollen_analysis, MAX(Price) AS Highest_Price
FROM cte
WHERE rank_price <= 3
GROUP BY Pollen_analysis;


-- Identify the honeys with the highest price within each CS category:
SELECT *
FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY CS ORDER BY Price DESC) AS Row_Num
    FROM honey
) AS ranked_data
WHERE Row_Num = 1;


-- Find the rows where 'Purity' is greater than 1 standard deviation above the mean 'Purity':
WITH purity_stats AS (
    SELECT AVG(CAST(Purity AS FLOAT)) AS mean_purity, STDEV(CAST(Purity AS FLOAT)) AS std_dev_purity
    FROM honey
)
SELECT * FROM honey
CROSS JOIN purity_stats
WHERE CAST(Purity AS FLOAT) > (mean_purity + std_dev_purity);


-- Calculate the difference between the maximum and minimum 'Viscosity' for each 'Pollen_analysis' group:
SELECT Pollen_analysis, MAX(CAST(Viscosity AS FLOAT)) - MIN(CAST(Viscosity AS FLOAT)) AS viscosity_range
FROM honey
GROUP BY Pollen_analysis;


-- Calculate the correlation between fructose and glucose levels in the honey samples:
SELECT COALESCE(
  (SUM(CAST(F AS FLOAT) * CAST(G AS FLOAT)) - SUM(CAST(F AS FLOAT)) * SUM(CAST(G AS FLOAT)) / COUNT(*)) /
  (SQRT(SUM(POWER(CAST(F AS FLOAT), 2)) - POWER(SUM(CAST(F AS FLOAT)), 2) / COUNT(*)) *
   SQRT(SUM(POWER(CAST(G AS FLOAT), 2)) - POWER(SUM(CAST(G AS FLOAT)), 2) / COUNT(*))),
  0
) AS fructose_glucose_correlation
FROM honey
WHERE F IS NOT NULL AND G IS NOT NULL;


-- Calculate the correlation between price and purity levels:
SELECT COALESCE(
  (SUM(CAST(Price AS FLOAT) * CAST(Purity AS FLOAT)) - SUM(CAST(Price AS FLOAT)) * SUM(CAST(Purity AS FLOAT)) / COUNT(*)) /
  (SQRT(SUM(POWER(CAST(Price AS FLOAT), 2)) - POWER(SUM(CAST(Price AS FLOAT)), 2) / COUNT(*)) *
   SQRT(SUM(POWER(CAST(Purity AS FLOAT), 2)) - POWER(SUM(CAST(Purity AS FLOAT)), 2) / COUNT(*))),
  0
) AS price_purity_correlation
FROM honey
WHERE Price IS NOT NULL AND Purity IS NOT NULL;


-- Find the top 3 'Pollen_analysis' groups with the highest average 'Price', and return the average 'Price', 'Purity', and 'Viscosity' for those groups:
WITH cte AS (
    SELECT Pollen_analysis,
           AVG(CAST(Price AS FLOAT)) AS avg_price,
           AVG(CAST(Purity AS FLOAT)) AS avg_purity,
           AVG(CAST(Viscosity AS FLOAT)) AS avg_viscosity,
           RANK() OVER (ORDER BY AVG(CAST(Price AS FLOAT)) DESC) AS rank_by_price
    FROM honey
    GROUP BY Pollen_analysis
)
SELECT Pollen_analysis, avg_price, avg_purity, avg_viscosity
FROM cte
WHERE rank_by_price <= 3;


-- Get the top 3 pollen types with the highest average viscosity, and return their average viscosity, purity, and price:
WITH cte AS (
    SELECT Pollen_analysis, AVG(CAST(Viscosity AS FLOAT)) AS avg_viscosity
    FROM honey
    GROUP BY Pollen_analysis
)
SELECT TOP 3 cte.Pollen_analysis, cte.avg_viscosity,
       AVG(CAST(Purity AS FLOAT)) AS avg_purity,
       AVG(CAST(Price AS FLOAT)) AS avg_price
FROM cte
JOIN honey ON cte.Pollen_analysis = honey.Pollen_analysis
GROUP BY cte.Pollen_analysis, cte.avg_viscosity
ORDER BY cte.avg_viscosity DESC;

















