# Queries

## Process Monitor

```` sql
-- what is the status of data transformation processes?
SELECT
  count(DISTINCT id) AS urls_possible
  ,count(DISTINCT CASE WHEN response_code IS NULL THEN id END) AS urls_todo
  ,count(DISTINCT CASE WHEN response_code = 404 THEN id END) AS urls_404
  ,count(DISTINCT CASE WHEN response_code = 200 THEN id END) AS urls_200
  ,count(DISTINCT CASE WHEN extracted = TRUE THEN id END) AS urls_extracted
  ,sum(row_count) AS rows_extracted
FROM data_urls;
/*
SELECT
  count(DISTINCT id) AS url_count
  ,count(DISTINCT CASE WHEN extracted = TRUE THEN id END) AS extracted_file_count

  ,round(
    count(DISTINCT CASE WHEN extracted = TRUE THEN id END)
    * 1.00 -- hack for pg decimal division
    / count(DISTINCT id)
  ,4) AS file_parsing_progress

  ,min(row_count) AS smallest_file_row_count
  ,max(row_count) AS largest_file_row_count

  ,sum(row_count) AS row_count
  ,sum(CASE WHEN extracted = TRUE THEN row_count ELSE 0 END) AS extracted_row_count

  ,round(
    sum(CASE WHEN extracted = TRUE THEN row_count ELSE 0 END)
    * 1.00 -- hack for pg decimal division
    / sum(row_count)
  ,4) AS row_parsing_progress
FROM data_urls;
*/
````

## Data Manipulation

```` sql
-- how to combine appointment date and appointment time into a datetime?
SELECT
    a.id
    ,a.date -- '07-MAY-14'
    ,to_date(a.date, 'DD-MON-YY') AS date_date
    ,a.time -- '08:00:00 AM'
    ,TO_TIMESTAMP(a.time, 'HH24:MI:SS')::TIME AS time_time
    ,to_date(a.date, 'DD-MON-YY') + TO_TIMESTAMP(a.time, 'HH24:MI:SS')::TIME AS appointment_at -- 2014-05-07 08:00:00
FROM appointments a;
````

```` sql
-- how to re-construct the flat/denormalized file structure (for use with tableau)?
SELECT
  v.id AS violation_id
  ,v.guid AS violation_guid
  ,v.description AS violation_description
  ,c.id AS citation_id
  ,c.guid AS citation_guid
  ,c.location AS citation_location
  ,c.payable AS citation_payable
  ,a.id AS appointment_id
  ,a.defendant_full_name
  ,a.room AS appointment_room
  ,a.date AS appointment_date
  ,a.time AS appointment_time
  ,to_date(a.date, 'DD-MON-YY') + TO_TIMESTAMP(a.time, 'HH24:MI:SS')::TIME AS appointment_datetime
FROM violations v
JOIN citations c ON c.violation_id = v.id
JOIN appointments a ON a.citation_id = c.id
ORDER BY violation_id, citation_id, appointment_id;
````

## Data Visualizations

```` sql
-- which violations have been cited the most?
SELECT
  v.id
  ,v.guid
  ,v.description
  ,count(DISTINCT c.id) AS citation_count
FROM violations v
JOIN citations c ON c.violation_id = v.id
GROUP BY 1,2,3
ORDER BY citation_count DESC
LIMIT 50;
````

```` sql
-- where do citations occur? (todo: geocode these addresses with an atlanta bounding box)
-- note: not all addresses have been stored with an equal amount of specificity and integrity
SELECT
  location
  ,count(DISTINCT id) AS citation_count
FROM citations c
GROUP BY 1
ORDER BY 2 DESC
LIMIT 50;
````

```` sql
-- how many average citations per person?
-- note: there is no way to determine unique person-level info, only unique names, which may be shared by multiple people...
-- note: this would be more interesting as a histogram. todo: look into using `width_bucket()` function
SELECT
  sum(citation_count) / count(DISTINCT defendant_full_name) AS avg_citations_per_person
FROM (  
  SELECT
    a.defendant_full_name
    ,count(DISTINCT c.id) AS citation_count
  FROM appointments a
  JOIN citations c ON a.citation_id = c.id
  GROUP BY 1
  ORDER BY 2 DESC
) citations_per_person;
````
