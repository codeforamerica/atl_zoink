# Queries

## Data Extraction and Performance Benchmarking

### Extraction

On production ...

```` sql
-- what are the statuses and results of data extraction processes?
SELECT
  count(DISTINCT id) AS urls_possible
  ,count(DISTINCT CASE WHEN response_code IS NULL THEN id END) AS urls_to_request
  ,count(DISTINCT CASE WHEN response_code = 404 THEN id END) AS urls_404
  ,count(DISTINCT CASE WHEN response_code = 200 THEN id END) AS urls_200
  ,count(DISTINCT CASE WHEN extracted_at IS NOT NULL THEN id END) AS urls_extracted
  ,count(DISTINCT CASE WHEN response_code = 200 THEN id END)
    - count(DISTINCT CASE WHEN extracted_at IS NOT NULL THEN id END) AS urls_to_extract
  ,sum(row_count) AS rows_extracted
FROM atlanta_endpoints;
````

=>

urls_possible | urls_to_request | urls_404 | urls_200 | urls_extracted | urls_to_extract | rows_extracted
--- | --- | --- | --- | --- | --- | ---
761 | 0 | 568 | 193 | 193 | 11 | 7083311


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
193 | 00:00:00.000215 | 00:00:37.273344 | 00:00:09.075946


... extraction per url takes between a fraction of a second and 9 seconds.

### Performance

On a macbook air not including data from 11 mal-encoded .csv files...

```` sql
SELECT count(DISTINCT id) FROM atlanta_endpoint_objects; -- > 6,734,949 rows; 6,520 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; -- > 390,831 rows; 231,604 ms
CREATE INDEX guid_index ON atlanta_endpoint_objects (guid); -- > 230,836 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; -- > 390,831 rows; 243,083 ms
````

... the full table of extracted objects is large and slow to query, and indexing is not a sufficient solution.

```` sql
SELECT count(DISTINCT id) FROM atlanta_endpoint_objects; --> 6,734,949 rows; 6,520 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; --> 390,831 rows; 243,083 ms
SELECT count(DISTINCT violation) FROM atlanta_endpoint_objects; --> 1,054 rows; 177,763 ms
SELECT count(DISTINCT description) FROM atlanta_endpoint_objects; --> 1,009 rows; 203,546 ms
SELECT count(DISTINCT defendant) FROM atlanta_endpoint_objects; --> 266,159 rows; 272,806 ms
SELECT count(DISTINCT location) FROM atlanta_endpoint_objects; --> 149,025 rows; 265,849 ms
SELECT count(DISTINCT room) FROM atlanta_endpoint_objects; --> 17 rows; 39,646 ms
SELECT count(DISTINCT time) FROM atlanta_endpoint_objects; --> 37 rows; 46,182 ms
````

On production including all available .csv files...

```` sql
SELECT count(DISTINCT id) FROM atlanta_endpoint_objects; -- > 7,083,311 rows ; 5,521 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; -- > 407,118 rows; 84,436 ms
SELECT count(DISTINCT violation) FROM atlanta_endpoint_objects; -- > 1,061 rows; 110,793 ms
SELECT count(DISTINCT description) FROM atlanta_endpoint_objects; -- > 1,016 rows; 230,537 ms
SELECT count(DISTINCT defendant) FROM atlanta_endpoint_objects; -- > 276,154 rows; 112,856 ms
SELECT count(DISTINCT location) FROM atlanta_endpoint_objects; -- > 154,036 rows; 143,123 ms
SELECT count(DISTINCT room) FROM atlanta_endpoint_objects; -- > 17 rows; 60,673 ms
SELECT count(DISTINCT time) FROM atlanta_endpoint_objects; -- > 38 rows; 97,966 ms
````

There seem to be moderate observational performance gains in production, but perhaps not reliable or significant.
