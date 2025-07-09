/* Create sdp and the sdp.enroll table */

-- Create the sdp database
DROP DATABASE IF EXISTS sdp;
CREATE DATABASE sdp;

-- Create the sdp.sdp_enroll table
DROP TABLE IF EXISTS sdp.sdp_enroll;
CREATE TABLE sdp.sdp_enroll (
	school_id INTEGER NOT NULL ,
	school_name VARCHAR(255) NOT NULL,
	year_school_opened INTEGER ,
	admission_type VARCHAR(255) ,
	governance VARCHAR(255) ,
	grade_K INTEGER ,
	grade_1 INTEGER ,
	grade_2 INTEGER ,
	grade_3 INTEGER ,
	grade_4 INTEGER ,
	grade_5 INTEGER ,
	grade_6 INTEGER ,
	grade_7 INTEGER ,
	grade_8 INTEGER ,
	grade_9 INTEGER ,
	grade_10 INTEGER ,
	grade_11 INTEGER ,
	grade_12 INTEGER ,
	school_year VARCHAR(255) NOT NULL,
	PRIMARY KEY (school_id, school_year)
);

INSERT INTO sdp.sdp_enroll (
	school_id,
	school_name,
	year_school_opened,
	admission_type,
	governance,
	grade_K,
	grade_1,
	grade_2,
	grade_3,
	grade_4,
	grade_5,
	grade_6,
	grade_7,
	grade_8,
	grade_9,
	grade_10,
	grade_11,
	grade_12,
	school_year
)(
	SELECT
	t2.school_id,
	t2.school_name,
	t1.year_school_opened,
	t1.admission_type,
	t1.governance,
	t1.grade_K,
	t1.grade_1,
	t1.grade_2,
	t1.grade_3,
	t1.grade_4,
	t1.grade_5,
	t1.grade_6,
	t1.grade_7,
	t1.grade_8,
	t1.grade_9,
	t1.grade_10,
	t1.grade_11,
	t1.grade_12,
	t1.school_year
FROM import_sdp.sdp_enroll as t1
INNER JOIN import_sdp.uniq_schl_list as t2
    ON t1.school_id = t2.school_id
);


/* Delete the import_sdp.sdp_enroll table  */

-- Delete the import_sdp.sdp_enroll table
DROP TABLE import_sdp.sdp_enroll;


/* Examine the structure of the sdp.sdp_enroll table */

-- Count the number of rows in the sdp.sdp_enroll table
SELECT COUNT(*) as num_rows
FROM sdp.sdp_enroll;

-- Count the number of columns in the sdp.sdp_enroll table
SELECT COUNT(*) as num_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_SCHEMA = 'sdp' AND
    TABLE_NAME = 'sdp_enroll';


/* Check a few assumptions */

-- Verify that schools are now uniquely identifiable
SELECT 
	COUNT(DISTINCT school_name) AS unique_school_names,
	COUNT(DISTINCT school_id) AS unique_school_ids,
    COUNT(DISTINCT school_name) - COUNT(DISTINCT school_id) AS diff
FROM sdp.sdp_enroll;


-- Verify that each school has only one row per school_year
SELECT
    school_id,
    school_year,
    COUNT(*) AS row_count
FROM sdp.sdp_enroll
GROUP BY 
	school_year, 
	school_id
HAVING COUNT(*) <> 1;

