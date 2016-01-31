# Queries

## Data Extraction

```` sql
-- what are the statuses and results of data extraction processes?
SELECT
  count(DISTINCT id) AS urls_possible
  ,count(DISTINCT CASE WHEN response_code IS NULL THEN id END) AS urls_to_request
  ,count(DISTINCT CASE WHEN response_code = 404 THEN id END) AS urls_404
  ,count(DISTINCT CASE WHEN response_code = 200 THEN id END) AS urls_200
  ,count(DISTINCT CASE WHEN extracted_at IS NOT NULL THEN id END) AS urls_extracted
  count(DISTINCT CASE WHEN response_code = 200 THEN id END)
    - count(DISTINCT CASE WHEN extracted_at IS NOT NULL THEN id END) AS urls_to_extract
  ,sum(row_count) AS rows_extracted
FROM atlanta_endpoints;
````

=>

urls_possible | urls_to_request | urls_404 | urls_200 | urls_extracted | urls_to_extract | rows_extracted
--- | --- | --- | --- | --- | --- | ---
759 | 0 | 566 | 193 | 182 | 11 | 6734949


```` sql
-- how long does the extraction process take?
SELECT
  COUNT(DISTINCT CASE WHEN extracted_at IS NOT NULL THEN upload_date END) AS extracted_url_count
  ,min(CASE WHEN extracted_at IS NOT NULL THEN extracted_at - response_received_at end) AS min_load_time
  ,max(CASE WHEN extracted_at IS NOT NULL THEN extracted_at - response_received_at end) AS max_load_time
  ,avg(CASE WHEN extracted_at IS NOT NULL THEN extracted_at - response_received_at end) AS avg_load_time
FROM atlanta_endpoints;
````

=>

extracted_url_count | min_load_time | max_load_time | avg_load_time
--- | --- | --- | ---
182 | 00:00:00.001321 | 00:00:06.93648 | 00:00:03.664559

... extraction per url takes between a fraction of a second and 6 seconds. these results are surprising. if true, this means the mass inserts methodology results in a marked speed improvement over prior methodologies which stored a row at a time.
