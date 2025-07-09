# An SQL data exploration project (with light wrangling) 

This project uses `MySQL` to perform light data wrangling and exploratory data analysis on a dataset that lists District, Charter, and Alternative Schools in the School District of Philadelphia from 2018-19 to 2024-25. The data for this project were downloaded from the [School District of Philadelphia's District Performance Office Open Data Portal](https://www.philasd.org/research/#opendata).

The goals of this project are to:

1. Assign a unique school name to all school IDs
2. Answer a few questions using the data

## Create the `import_sdp` database and `sdp_enroll` table

The script to create both the `import_sdp` database and the `sdp_enroll` table can be found in the scripts folder at `./scripts/sql_import.sql`.

### Create `import_sdp`

First, create a new database called `import_sdp`. This database and tables contained within it will serve as temporary objects so we can learn a little bit more about the dataset and any changes that need to be made. 

```sql
-- Create the import_sdp database
DROP DATABASE IF EXISTS import_sdp;
CREATE DATABASE import_sdp;
```

### Create the `import_sdp.sdp_enroll` table

Next, create a table called `sdp_enroll` with nineteen columns:

* `school_id`: A unique location identification number assigned to each school in the School District of Philadelphia's Uniform Location Code System (ULCS) system.
* `school_name`: School name.
* `year_school_opened`: A four-digit number indicating when the school was first established.
* `admission_type`: A description of the school's admissions policy. Possible values include:  Neighborhood, Citywide, Special Admit, Citywide with Criteria, and Alternative.
* `governance`: A description of the school's governance. Possible values include:  District, Charter, or Contracted.
* `grade_K`: Flag indicating whether school serves Kindergarten in the specified school year. 
* `grade_1`: Flag indicating whether school serves 1st grade in the specified school year. 
* `grade_2`: Flag indicating whether school serves 2nd grade in the specified school year. 
* `grade_3`: Flag indicating whether school serves 3rd grade in the specified school year. 
* `grade_4`: Flag indicating whether school serves 4th grade in the specified school year. 
* `grade_5`: Flag indicating whether school serves 5th grade in the specified school year. 
* `grade_6`: Flag indicating whether school serves 6th grade in the specified school year. 
* `grade_7`: Flag indicating whether school serves 7th grade in the specified school year. 
* `grade_8`: Flag indicating whether school serves 8th grade in the specified school year. 
* `grade_9`: Flag indicating whether school serves 9th grade in the specified school year. 
* `grade_10`: Flag indicating whether school serves 10th grade in the specified school year. 
* `grade_11`: Flag indicating whether school serves 11th grade in the specified school year. 
* `grade_12`: Flag indicating whether school serves 12th grade in the specified school year. 
* `school_year`: A seven-character identifier representing the school year the row of data is associated with.

This new table will contain multiple rows with the same `school_id` and the same `school_year`, so neither of these columns is unique on its own. However, each school is represented only once per school year, meaning that the combination of these two columns can be used as a `PRIMARY KEY` to uniquely identify each row.

```sql
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
```

Finally, load data from the `sdp_school_list_1819_2425.csv` file into the `import_sdp.sdp_enroll` table.

```sql
-- Load data into the import_sdp.sdp_enroll table
LOAD DATA LOCAL INFILE "./data/sdp_school_list_1819_2425.csv" 
INTO TABLE import_sdp.sdp_enroll
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;
```

### Explore the `import_sdp.sdp_enroll` table

#### Dimensions of the table

Print the dimensions of the `import_sdp.sdp_enroll` table.

First, count all of the rows:

```sql
-- Count the number of rows in the sdp.sdp_enroll table
SELECT COUNT(*) as num_rows
FROM import_sdp.sdp_enroll;
```

| num_rows |
|----------|
| 2301     |


Next, count all of the columns

```sql
-- Count the number of columns in the sdp.sdp_enroll table
SELECT COUNT(*) as num_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_SCHEMA = 'import_sdp' AND
    TABLE_NAME = 'sdp_enroll';
```

| num_columns |
|-------------|
|          19 |

#### Are schools uniquely identifiable?

What is the total number of unique school IDs in the dataset?

```sql
-- Count the unique number of school IDs
SELECT 
	COUNT(DISTINCT school_id) AS unique_num_school_ids
FROM import_sdp.sdp_enroll;
```

| unique_num_school_ids |
|-----------------------|
| 343                   |

Let's see if that number equals the unique number of school names

```sql
-- Count the unique number of school names
SELECT 
	COUNT(DISTINCT school_name) AS unique_num_school_names
FROM import_sdp.sdp_enroll;
```

| unique_num_school_names |
|-------------------------|
| 407                     |

The numbers don't match, indicating that the same school, identified by its `school_id`, has different names across school years. We can identify these schools using their school_id:

```sql
SELECT
    school_id,
    COUNT(DISTINCT school_name) AS num_schl_variants
FROM import_sdp.sdp_enroll
GROUP BY school_id
HAVING num_schl_variants > 1;
```

(Partial table displayed for brevity.)

| school_id | num_schl_variants |
|-----------|-------------------|
| 1130      | 2                 |
| 1280      | 2                 |
| 2020      | 2                 |
| 2140      | 2                 |
| 2160      | 2                 |
| 2310      | 3                 |
| 2410      | 2                 |
| 2480      | 2                 |
| 2510      | 2                 |
| 2530      | 3                 |


### Assigning a unique name to each school id

Since a single `school_id` is linked to multiple school names, we need to standardize the school names for analysis. To accomplish this goal, we'll create a table containing a unique list of school IDs and their corresponding names, using the most recent name on record for each school. You can find all the examples executed in this section in the file `./scripts/sql_stnd.sql`.

```sql
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

Select * 
FROM import_sdp.uniq_schl_list;
```

(Partial table displayed for brevity.)

| school_id |                     school_name                     |
|-----------|-----------------------------------------------------|
| 6090      | A. Philip Randolph Career and Technical High School |
| 8010      | Abraham Lincoln High School                         |
| 2520      | Abram S. Jenks School                               |
| 2620      | Academy at Palumbo                                  |
| 6480      | Academy for the Middle Years at Northwest           |
| 2310      | Achieve Academy of Philadelphia                     |
| 3820      | Achieve Academy of Philadelphia - East Campus       |
| 3379      | Ad Prima Charter School                             |
| 1460      | Add B. Anderson School                              |
| 1470      | Alain Locke School                                  |
| 2470      | Albert M. Greenfield School                         |
| 5200      | Alexander Adaire School                             |
| 7380      | Alexander K. McClure School                         |
| 7290      | Allen M. Stearne School                             |
| 3315      | Alliance For Progress Charter School                |


## Create the `sdp` database and `sdp_enroll` table

Now that we have a deduplicated list of school names (`import_sdp.uniq_schl_list`), each linked to a unique `school_id`, we're ready to move on to the next phase. Create a new database called `sdp`, which will contain a single table: `sdp_enroll`. This table will include the standardized school names along with a selected subset of columns from the original `import_sdp.sdp_enroll` table:

* `school_id`
* `school_name`
* `year_school_opened`
* `admission_type`
* `governance`
* `grade_K`
* `grade_1`
* `grade_2`
* `grade_3`
* `grade_4`
* `grade_5`
* `grade_6`
* `grade_7`
* `grade_8`
* `grade_9`
* `grade_10`
* `grade_11`
* `grade_12`
* `school_year`

### Create `sdp`

First, create the `sdp` database. You can find all the examples executed in this section in the file `./scripts/sql_sdp.sql`.


```sql
-- Create the sdp database
DROP DATABASE IF EXISTS sdp;
CREATE DATABASE sdp;
```

### Create the `sdp_enroll` table

Next, create a new table named `sdp_enroll` within the `sdp` database. Instead of using the old school names, merge data from two `tables—import_sdp.sdp_enroll` (aliased as t1) and `import_sdp.uniq_schl_list` (aliased as t2)—by matching on school_id. This ensures that each `school_id` in the new table is linked to a unique, standardized school name. You can find all the examples executed in this section in the file `./scripts/sql_sdp.sql`.


```sql
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
```

Now we can delete our original `import_sdp.sdp_enroll` table.

```sql
-- Delete the import_sdp.sdp_enroll table
DROP TABLE import_sdp.sdp_enroll;
```

### Explore the dimensions of the `sdp.sdp_enroll` table

Find the dimensions of the `sdp.sdp_enroll` table. You can find all the examples executed in this section in the file `./scripts/sql_sdp.sql`.

First, count all of the rows:

```sql
-- rows
SELECT COUNT(*) as num_rows
FROM sdp.sdp_enroll;
```

| num_rows |
|----------|
| 2301     |


Next, count all of the columns

```sql
-- columns
SELECT COUNT(*) as num_columns
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
	TABLE_SCHEMA = 'sdp' AND
    TABLE_NAME = 'sdp_enroll';
```

| num_columns |
|-------------|
|          19 |

### Are schools uniquely identifiable?

Let's confirm that the number of unique school names equals the unique number of school IDs. You can find all the examples executed in this section in the file `./scripts/sql_sdp.sql`.

```sql
SELECT 
	COUNT(DISTINCT school_name) AS unique_school_names,
	COUNT(DISTINCT school_id) AS unique_school_ids,
    COUNT(DISTINCT school_name) - COUNT(DISTINCT school_id) AS diff
FROM sdp.sdp_enroll;
```

| unique_school_names | unique_school_ids | diff |
|---------------------|-------------------|------|
| 343                 | 343               | 0    |


### Verify that each school has only one row per `school_year`

In the previous section, we discovered that unique school IDs were associated with multiple school names. One final check before we can begin answering questions with the data is to confirm that each school has only one row per `school_year`. Having multiple rows per `school_year` for schools can cause inaccurate calculations and duplicate data, which can affect the integrity of the analysis. You can find all the examples executed in this section in the file `./scripts/sql_sdp.sql`.

```sql
SELECT
    school_id,
    school_year,
    COUNT(*) AS row_count
FROM sdp.sdp_enroll
GROUP BY 
	school_year, 
	school_id
HAVING COUNT(*) <> 1;
```

Empty set (0.01 sec)

The query returned an empty result set, which means it executed successfully but found no matching rows. This confirms that each school appears only once per school year. With that verified, we’re ready to use the data to start answering some questions!


## Answer a few questions using the `sdp.sdp_enroll` table

We’re now ready to answer a few questions using the `sdp.sdp_enroll table`. All the examples from this section can be found in the file `./scripts/sql_eda.sql`.

<br>

1.  How many schools are listed for each school year?

```sql
SELECT 
	school_year, 
	COUNT(school_id) as total_school_counts
FROM sdp.sdp_enroll
GROUP BY school_year
ORDER BY school_year;
```

| school_year | total_school_counts |
|-------------|---------------------|
| 2018-19     | 329                 |
| 2019-20     | 329                 |
| 2020-21     | 328                 |
| 2021-22     | 326                 |
| 2022-23     | 329                 |
| 2023-24     | 329                 |
| 2024-25     | 331                 |

<br>

2.  Which school year had the greatest number of schools?

```sql
SELECT 
	school_year, 
	COUNT(school_id) as school_counts
FROM sdp.sdp_enroll
GROUP BY school_year
ORDER BY school_counts DESC
LIMIT 1;
```

| school_year | school_counts |
|-------------|---------------|
| 2024-25     | 331           |

<br>

3.  How many records are there for each school in the dataset?

```sql
SELECT 
	school_name, 
	COUNT(school_name) as school_counts
FROM sdp.sdp_enroll
GROUP BY school_name
ORDER BY school_counts, school_name;
```

<br>

(Partial table displayed for brevity.)

|                         school_name                          | school_counts |
|--------------------------------------------------------------|---------------|
| Eastern University Academy Charter School                    | 1             |
| Khepera Charter School                                       | 1             |
| Philadelphia Continuation Academy                            | 1             |
| Student Transition Center                                    | 1             |
| The Academy of Continued Education School                    | 1             |
| Architecture and Design Charter School                       | 2             |
| Excel Academy Central                                        | 2             |
| Guion S. Bluford School                                      | 2             |
| John B. Stetson Middle School                                | 3             |
| KIPP Octavius Catto Charter School                           | 3             |
| KIPP West Philadelphia Preparatory Charter School            | 3             |
| Olney High School                                            | 3             |
| Olney High School Continuation Academy                       | 3             |
| One Bright Ray - Simpson Evening                             | 3             |
| Philadelphia OIC Workforce Academy                           | 3             |
| Stetson Middle School Continuation Academy                   | 3             |
| Aspira Charter School at Olney                               | 4             |
| Aspira Charter School at Stetson                             | 4             |
| Austin Meehan School                                         | 4             |
| Northeast Community Propel Academy                           | 4             |
| Universal Charter School at Daroff                           | 4             |
| Bluford Charter School                                       | 5             |
| Ombudsman Northwest                                          | 5             |
| MAST Community Charter School III                            | 6             |
| Math, Civics and Sciences Charter School                     | 6             |
| Philadelphia Hebrew Public Charter School                    | 6             |
| Re-Engagement Center                                         | 6             |
| A. Philip Randolph Career and Technical High School          | 7             |
| Abraham Lincoln High School                                  | 7             |

<br>

4.  How many records are there for the school `Julia R. Masterman`?

```sql
SELECT 
    school_name,
    COUNT(school_name) AS num_records
FROM sdp.sdp_enroll
WHERE school_name LIKE '%masterman%'
GROUP BY school_name;
```

|          school_name           | num_records   |
|--------------------------------|---------------|
| Julia R. Masterman High School | 7             |

<br>

5.  What is the count of unique schools grouped by the number of times they appear in the dataset?


```sql
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

--- Can also be written as
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
```

| num_records | num_schools |
|-------------|-------------|
| 1           | 5           |
| 2           | 3           |
| 3           | 8           |
| 4           | 5           |
| 5           | 2           |
| 6           | 4           |
| 7           | 316         |


<br>

6. How many unique schools have exactly one record in the dataset?

```sql
SELECT COUNT(school_name) as one_record_schls
FROM (
	SELECT
		school_name
	FROM sdp.sdp_enroll
	GROUP BY school_name
	HAVING COUNT(school_name) = 1
) AS school_n_1;

--- Can also be written as
-- WITH school_n_1 AS (
-- 	SELECT
-- 		school_name
-- 	FROM sdp.sdp_enroll
-- 	GROUP BY school_name
-- 	HAVING COUNT(school_name) = 1
-- )
-- SELECT COUNT(school_name) AS one_record_schls
-- FROM school_n_1;
```

| one_record_schls |
|------------------|
| 5                |

<br>

7. How many schools appeared on the 2022-23 AND 2023-24 school year lists?

```sql
SELECT COUNT(school_name) as schls_2223_2324
FROM (
		SELECT
			school_name
		FROM sdp.sdp_enroll
		GROUP BY school_name
		HAVING 
			SUM(school_year = '2022-23') = 1 AND
			SUM(school_year = '2023-24') = 1
) AS school_count;

--- Can also be written as
-- WITH school_count AS (
-- 	SELECT
-- 			school_name
-- 	FROM sdp.sdp_enroll
-- 	GROUP BY school_name
-- 	HAVING 
-- 		SUM(school_year = '2022-23') = 1 AND
-- 		SUM(school_year = '2023-24') = 1
-- )
-- SELECT COUNT(school_name) AS schls_2223_2324
-- FROM school_count;
```

| schls_2223_2324 |
|-------------------|
| 327               |

<br>

8. In the 2023–24 school year, how many schools were District-run versus non-District?

We know from our codebook that possible values for the `governance` column include:

* District
* Charter
* Contracted

We can use this information to create a subquery that

* filters the dataset where school_year equals `2023-24`  
* creates a new column called `is_district`
* then counts the number of rows where the values `Yes` and `No` appear

```sql
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
```

| is_district | counts |
|-------------|--------|
| No          | 101    |
| Yes         | 228    |

<br>

9. Based on the year they established, what are the three oldest schools in the dataset?

```sql
SELECT 
	DISTINCT
		school_name,
		min(year_school_opened) AS year_school_opened
FROM sdp.sdp_enroll
GROUP BY school_name
ORDER BY year_school_opened
LIMIT 3;
```

|         school_name          | year_school_opened |
|------------------------------|--------------------|
| Francis S. Key School        | 1889               |
| Abram S. Jenks School        | 1897               |
| Fitler Academics Plus School | 1898               |

<br>

10. In which year was the most recently opened school established?

```sql
SELECT 
	DISTINCT
		school_name,
		max(year_school_opened) AS year_school_opened
FROM sdp.sdp_enroll
GROUP BY school_name
ORDER BY year_school_opened DESC
LIMIT 1;
```

|            school_name            | year_school_opened |
|-----------------------------------|--------------------|
| Philadelphia Continuation Academy | 2024               |

<br>

11. In the 2024-25 school year, how many and what percent of schools' admissions policy included a catchment area or neighborhood as a criteria


```sql
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
```
| is_catch_neigh | counts | percent |
|----------------|--------|---------|
| No             | 134    | 0.4048  |
| Yes            | 197    | 0.5952  |

<br>

12. In the 2024-25 school year, how many schools served middle school students (Grades 6 - 8)


```sql
SELECT COUNT(*) AS total_num_ms
FROM sdp.sdp_enroll
WHERE school_year = '2024-25'
    AND (COALESCE(grade_6, 0) + COALESCE(grade_7, 0) + COALESCE(grade_8, 0)) > 0;
```

| total_num_ms |
|--------------|
| 198          |


