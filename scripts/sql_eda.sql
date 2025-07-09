
/* Begin exploratory analysis */

-- 1.  How many schools are listed for each school year?

SELECT 
	school_year, 
	COUNT(school_id) as total_school_counts
FROM sdp.sdp_enroll
GROUP BY school_year
ORDER BY school_year;


-- 2.  Which school year had the greatest number of schools?

SELECT 
	school_year, 
	COUNT(school_id) as school_counts
FROM sdp.sdp_enroll
GROUP BY school_year
ORDER BY school_counts DESC
LIMIT 1;


-- 3.  How many records are there for each school in the dataset?

SELECT 
	school_name, 
	COUNT(school_name) as school_counts
FROM sdp.sdp_enroll
GROUP BY school_name
ORDER BY school_counts, school_name;


-- 4.  How many records are there for the school `Julia R. Masterman`?

SELECT 
    school_name,
    COUNT(school_name) AS num_records
FROM sdp.sdp_enroll
WHERE school_name LIKE '%masterman%'
GROUP BY school_name;


-- 5.  What is the count of unique schools grouped by the number of times they appear in the dataset?

SELECT 
	num_records,
    COUNT(num_records) AS num_schools
FROM (
    SELECT 
        COUNT(school_name) AS num_records
    FROM sdp.sdp_enroll
    GROUP BY school_name
) AS school_counts_sub
GROUP BY num_records
ORDER BY num_records;

-- Can also be written as
-- WITH school_n AS (
-- 	SELECT 
-- 		school_name, 
-- 		COUNT(school_name) as num_records
-- 	FROM sdp.sdp_enroll
-- 	GROUP BY school_name
-- )
-- SELECT 
-- 	num_records, 
-- 	COUNT(num_records) AS num_schools
-- FROM school_n
-- GROUP BY num_records
-- ORDER BY num_records;


-- 6. How many unique schools have exactly one record in the dataset?

SELECT COUNT(school_name) as one_record_schls
FROM (
	SELECT
		school_name
	FROM sdp.sdp_enroll
	GROUP BY school_name
	HAVING COUNT(school_name) = 1
) AS school_n_1;

-- Can also be written as
-- WITH school_n_1 AS (
-- 	SELECT
-- 		school_name
-- 	FROM sdp.sdp_enroll
-- 	GROUP BY school_name
-- 	HAVING COUNT(school_name) = 1
-- )
-- SELECT COUNT(school_name) AS one_record_schls
-- FROM school_n_1;


-- 7. How many schools appeared on the 2022-23 AND 2023-24 school year lists?

SELECT COUNT(school_name) as schls_22_23_23_24
FROM (
		SELECT
			school_name
		FROM sdp.sdp_enroll
		GROUP BY school_name
		HAVING 
			SUM(school_year = '2022-23') = 1 AND
			SUM(school_year = '2023-24') = 1
) AS school_count;

-- Can also be written as
-- WITH school_count AS (
-- 	SELECT
-- 			school_name
-- 	FROM sdp.sdp_enroll
-- 	GROUP BY school_name
-- 	HAVING 
-- 		SUM(school_year = '2022-23') = 1 AND
-- 		SUM(school_year = '2023-24') = 1
-- )
-- SELECT COUNT(school_name) AS schls_22_23_23_24
-- FROM school_count;


-- 8. In the 2023–24 school year, how many schools were District-run versus non-District?

-- We know from our codebook that possible values for the `governance` column include:
-- * District
-- * Charter
-- * Contracted

SELECT 
	is_district,
	COUNT(is_district) as counts
FROM (
	SELECT 
		CASE governance
			WHEN 'District' THEN 'Yes'
			ELSE 'No'
		END AS is_district	
	FROM sdp.sdp_enroll
	WHERE school_year = '2023-24'
) AS district_flag
GROUP BY is_district
ORDER BY is_district;

-- Can also be written as
-- WITH district_flag AS (
-- 	SELECT 
-- 		CASE governance
-- 			WHEN 'District' THEN 'Yes'
-- 			ELSE 'No'
-- 		END AS is_district
-- 	FROM sdp.sdp_enroll
-- 	WHERE school_year = '2023-24'
-- )
-- SELECT 
-- 	is_district,
-- 	COUNT(is_district) as counts
-- FROM district_flag
-- GROUP BY is_district
-- ORDER BY is_district;


-- 9. Based on the year they established, what are the three oldest schools in the dataset?

SELECT 
	DISTINCT
		school_name,
		min(year_school_opened) AS year_school_opened
FROM sdp.sdp_enroll
GROUP BY school_name
ORDER BY year_school_opened
LIMIT 3;


-- 10. In which year was the most recently opened school established?

SELECT 
	DISTINCT
		school_name,
		max(year_school_opened) AS year_school_opened
FROM sdp.sdp_enroll
GROUP BY school_name
ORDER BY year_school_opened DESC
LIMIT 1;


-- 11. In the 2024-25 school year, how many and what percent of schools' admissions policy included a catchment area or neighborhood as a criteria

SELECT 
	is_catch_neigh,
	COUNT(is_catch_neigh) AS counts,
	COUNT(is_catch_neigh)/(SUM(COUNT(is_catch_neigh)) OVER()) as percent
FROM (SELECT
		CASE 
			WHEN admission_type REGEXP 'catchment|neighborhood' THEN 'Yes'
			ELSE 'No'
    	END AS is_catch_neigh
		FROM sdp.sdp_enroll
		WHERE school_year = '2024-25'
) AS categorized
GROUP BY is_catch_neigh
ORDER BY is_catch_neigh;


-- 12. In the 2024-25 school year, how many schools served middle school students (Grades 6 - 8)

SELECT COUNT(*) AS total_num_ms
FROM sdp.sdp_enroll
WHERE school_year = '2024-25'
    AND (COALESCE(grade_6, 0) + COALESCE(grade_7, 0) + COALESCE(grade_8, 0)) > 0;

