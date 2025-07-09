/* Create import_sdp and the import_sdp.sdp_enroll table */

-- Create the import_sdp database
DROP DATABASE IF EXISTS import_sdp;
CREATE DATABASE import_sdp;

-- Define a new table within the import_sdp database
DROP TABLE IF EXISTS import_sdp.sdp_enroll;
CREATE TABLE import_sdp.sdp_enroll (
	school_id INTEGER NOT NULL,
	school_name VARCHAR(255) NOT NULL,
	year_school_opened INTEGER,
	admission_type VARCHAR(255),
	governance VARCHAR(255),
	grade_K INTEGER,
	grade_1 INTEGER,
	grade_2 INTEGER,
	grade_3 INTEGER,
	grade_4 INTEGER,
	grade_5 INTEGER,
	grade_6 INTEGER,
	grade_7 INTEGER,
	grade_8 INTEGER,
	grade_9 INTEGER,
	grade_10 INTEGER,
	grade_11 INTEGER,
	grade_12 INTEGER,
	school_year VARCHAR(255) NOT NULL,
	PRIMARY KEY(school_id, school_year)
);

-- Load data into the import_sdp.sdp_enroll table
LOAD DATA LOCAL INFILE "./data/sdp_school_list_1819_2425.csv" 
INTO TABLE import_sdp.sdp_enroll
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


/* Examine the structure of the sdp.sdp_enroll table */

-- Count the number of rows in the sdp.sdp_enroll table
SELECT COUNT(*) as num_rows
FROM import_sdp.sdp_enroll;

-- Count the number of columns in the sdp.sdp_enroll table
SELECT COUNT(*) as num_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_SCHEMA = 'import_sdp' AND
    TABLE_NAME = 'sdp_enroll';


/* Counting unique school IDs and school names */

-- Count the unique number of school IDs
SELECT 
	COUNT(DISTINCT school_id) AS unique_num_school_ids
FROM import_sdp.sdp_enroll;

-- Count the unique number of school names
SELECT 
	COUNT(DISTINCT school_name) AS unique_num_school_names
FROM import_sdp.sdp_enroll;
	
/* Create the import_sdp.uniq_schl_list table */

-- Create a new table containing a unique list of school names and ids. 
DROP TABLE IF EXISTS import_sdp.uniq_schl_list;
CREATE TABLE import_sdp.uniq_schl_list AS (
SELECT 
    school_id, 
    school_name
FROM import_sdp.sdp_enroll
WHERE (school_id, school_year) IN (
    SELECT school_id, MAX(school_year)
    FROM import_sdp.sdp_enroll
    GROUP BY school_id
	)
)
ORDER BY school_name;

-- Print the import_sdp.uniq_schl_list table
Select * 
FROM import_sdp.uniq_schl_list;

