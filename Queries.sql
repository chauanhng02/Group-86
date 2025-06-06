-- QUESTION 1
SELECT
    c.country_location AS "Country",
    '2022-12-31' AS "Date 1",
    s1.cumulative_vaccinations AS "Vaccine on OD1",
    '2023-01-04' AS "Date 2",
    s2.cumulative_vaccinations AS "Vaccine on OD2",
    '2023-01-08' AS "Date 3",
    s3.cumulative_vaccinations AS "Vaccine on OD3",
    ROUND(
        (
            ((s2.cumulative_vaccinations - s1.cumulative_vaccinations) * 100.0 / NULLIF(s1.cumulative_vaccinations, 0)) -
            ((s3.cumulative_vaccinations - s2.cumulative_vaccinations) * 100.0 / NULLIF(s2.cumulative_vaccinations, 0))
        ), 2
    ) AS "Percentage change of totals"
FROM
    Country c
JOIN
    (SELECT iso_code, date, SUM(daily_vaccinations) OVER (PARTITION BY iso_code ORDER BY date) AS cumulative_vaccinations FROM Country_Vaccination_Metrics WHERE date <= '2022-12-31') s1 ON c.iso_code = s1.iso_code
JOIN
    (SELECT iso_code, date, SUM(daily_vaccinations) 
    OVER (PARTITION BY iso_code ORDER BY date) AS cumulative_vaccinations 
    FROM Country_Vaccination_Metrics 
    WHERE date <= '2023-01-04') s2 ON c.iso_code = s2.iso_code
JOIN
    (SELECT iso_code, date, SUM(daily_vaccinations) 
    OVER (PARTITION BY iso_code ORDER BY date) AS cumulative_vaccinations 
    FROM Country_Vaccination_Metrics 
    WHERE date <= '2023-01-08') s3 ON c.iso_code = s3.iso_code
WHERE
    s1.date = '2022-12-31' AND
    s2.date = '2023-01-04' AND
    s3.date = '2023-01-08'
ORDER BY
    "Percentage change of totals" DESC;


-- QUESTION 2
SELECT 
    C.country_location AS "Country",
    strftime('%m', cvm.date) AS "Month",
    strftime('%Y', cvm.date) AS "Year",
    ROUND((cvm.total_vaccinations_this_month * 1.0 / NULLIF(cvm.total_vaccinations_last_month, 0)), 2) AS "Growth rate of vaccine (GR)",
    ROUND(((cvm.total_vaccinations_this_month * 1.0 / NULLIF(cvm.total_vaccinations_last_month, 0)) - globalavg.avg_growth_rate), 2) AS "Difference of growth rate to global average"
FROM (SELECT iso_code, date,
            SUM(total_vaccinations) AS total_vaccinations_this_month,
            (SELECT SUM(total_vaccinations)
             FROM Country_Vaccination_Metrics
             WHERE iso_code = cvm.iso_code
             AND strftime('%Y-%m', date) = strftime('%Y-%m', datetime(cvm.date, '-1 month'))) 
             AS total_vaccinations_last_month
            FROM Country_Vaccination_Metrics cvm
            GROUP BY iso_code, strftime('%Y-%m', date)
        ) cvm
JOIN Country C ON C.iso_code = cvm.iso_code
JOIN (SELECT strftime('%Y-%m', date) AS month_year,
          AVG(total_vaccinations_this_month * 1.0 / NULLIF(total_vaccinations_last_month, 0)) 
          AS avg_growth_rate
          FROM (SELECT iso_code, date,
                SUM(total_vaccinations) AS total_vaccinations_this_month,
                (SELECT SUM(total_vaccinations)
                 FROM Country_Vaccination_Metrics
                 WHERE iso_code = innerCVM.iso_code
                 AND strftime('%Y-%m', date) = strftime('%Y-%m', datetime(innerCVM.date, '-1 month'))
                ) AS total_vaccinations_last_month
            FROM Country_Vaccination_Metrics innerCVM
            GROUP BY iso_code, strftime('%Y-%m', date)
            )
            GROUP BY month_year
        ) globalavg ON strftime('%Y-%m', cvm.date) = globalavg.month_year
WHERE cvm.total_vaccinations_last_month > 0
AND (cvm.total_vaccinations_this_month * 1.0 / NULLIF(cvm.total_vaccinations_last_month, 0)) > globalavg.avg_growth_rate
ORDER BY C.country_location, strftime('%Y-%m', cvm.date);


-- QUESTION 3 
SELECT 
    vaccine AS "Vaccine Type", 
    iso_code AS "Country", 
    "Percentage of Vaccine Type"
FROM (SELECT 
            MV.iso_code, 
            MV.vaccine, 
            ROUND((SUM(MV.total_vaccinations) * 100.0 / total_in_country), 3) AS "Percentage of Vaccine Type",
            ROW_NUMBER() OVER (
                PARTITION BY MV.iso_code
                ORDER BY (SUM(MV.total_vaccinations) * 100.0 / total_in_country) DESC
            ) AS "Ranking by Country"
        FROM Manufacturer_Vaccination AS MV
        JOIN (SELECT 
                    iso_code, 
                    SUM(total_vaccinations) AS total_in_country
                    FROM Manufacturer_Vaccination
                    GROUP BY iso_code
                 ) AS subMV 
        ON MV.iso_code = subMV.iso_code
        GROUP BY MV.iso_code, MV.vaccine, total_in_country
        ) AS RankedVaccines
WHERE "Ranking by Country" <= 5
ORDER BY iso_code, "Percentage of Vaccine Type" DESC;


-- QUESTION 4
SELECT 
    C.country_location AS "Country Name",
    strftime('%Y-%m', CVM.date) AS "Month",
    COALESCE(single_source.source_url, CS.source_url) AS "Source URL",
    SUM(CVM.total_vaccinations) AS "Total Administered Vaccines"
FROM Country C
LEFT JOIN  Country_Vaccination_Metrics CVM ON C.iso_code = CVM.iso_code
LEFT JOIN Country_Source CS ON C.iso_code = CS.iso_code AND CVM.date = CS.date
LEFT JOIN (
    SELECT 
        iso_code,
        MAX(source_url) AS source_url
    FROM Country_Source
    GROUP BY iso_code
    HAVING COUNT(DISTINCT source_url) = 1
) AS single_source ON C.iso_code = single_source.iso_code
GROUP BY C.country_location, strftime('%Y-%m', CVM.date), COALESCE(single_source.source_url, CS.source_url)
ORDER BY SUM(CVM.total_vaccinations) DESC;


-- QUESTION 5
SELECT 
    date AS "Dates",
    COALESCE(MAX(CASE WHEN iso_code = 'USA' THEN daily_increase END), 0) AS "United States",
    COALESCE(MAX(CASE WHEN iso_code = 'CHN' THEN daily_increase END), 0) AS "China",
    COALESCE(MAX(CASE WHEN iso_code = 'IRL' THEN daily_increase END), 0) AS "Ireland",
    COALESCE(MAX(CASE WHEN iso_code = 'IND' THEN daily_increase END), 0) AS "India"
FROM (
    SELECT 
        date,
        iso_code,
        people_fully_vaccinated - LAG(people_fully_vaccinated, 1, 0) OVER (PARTITION BY iso_code ORDER BY date) AS daily_increase
    FROM 
        Country_Vaccination_Metrics
    WHERE 
        iso_code IN ('USA', 'CHN', 'IRL', 'IND')
        AND strftime('%Y', date) IN ('2022', '2023')
)
GROUP BY date
ORDER BY date;
