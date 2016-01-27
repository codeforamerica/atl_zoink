# Queries

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

=> ?
