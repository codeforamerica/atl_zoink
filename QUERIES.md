# Queries

## Data Extraction

```` sql
-- what are the statuses and result of data extraction processes?
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






<hr>

## Data Observation

> NOTE: the results below do not (yet) include data from the 11 files which have ascii encoding ...

The full table of extracted objects is large and slow to query. And indexing may not be an applicable solution.

```` sql
SELECT count(DISTINCT id) FROM atlanta_endpoint_objects; -- > 6,734,949 rows; 6,520 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; -- > 390,831 rows; 231,604 ms
CREATE INDEX guid_index ON atlanta_endpoint_objects (guid); -- > 230,836 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; -- > 390,831 rows; 243,083 ms
````

### Summary Statistics and Findings

```` sql
SELECT count(DISTINCT id) FROM atlanta_endpoint_objects; -- > 6,734,949 rows; 6,520 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; -- > 390,831 rows; 243,083 ms
SELECT count(DISTINCT violation) FROM atlanta_endpoint_objects; -- > 1054 rows; 177,763 ms
````


#### Duplicate Violation Descriptions

```` sql
SELECT
  v.description
  ,count(DISTINCT v.id) AS guid_count
  ,count(DISTINCT v.id) AS id_count
FROM violations v
GROUP BY 1
HAVING count(DISTINCT v.id) > 1 OR count(DISTINCT v.id) > 1
ORDER BY 3 DESC;
````

=>

description | guid_count | guid_list
--- | --- | ---
POSS/MANU/ETC. CONTROL SUB | 4 | 16-13-30(J),  16-13-30(A),  16-13-30(J)(1),  16-13-30
IMPROPER STOPPING ON ROADWAY | 4 | 40-6-203(A)(1)(A),  40-6-203.C,  40-6-203(A),  40-6-203(A)1
FAILURE TO MAINTAIN INSURANCE | 3 | 40-6-10A,  40-6-10.,  40-6-10B
FAILURE TO USE CORRECT SIGNAL | 2 | 40-6-123.B,  40-6-123(B)
FOLLOWING TOO CLOSELY | 2 | 40-6-49(A),  40-6-49
IMPROPER LANE CHANGE | 2 | 40-6-123(A),  40-6-123.A
NO HELMET | 2 | 40-6-315.A,  40-6-315(A)
OPERATE VEH WITHOUT INSURANCE | 2 | 40-6-10.B,  40-6-10.A
PASSING ON HILL OR CURVE | 2 | 40-6-45(A),  40-6-45(A)1
PASSING ON SHOULDER OF ROAD | 2 | 40-6-43(B),  40-6-43.B
POSSESSION OF MARIJUANA | 2 | 16-13-2(B),  16-13-2B
DEFECATE OR URINATE ON | 2 | 10-9(A)(2),  10-9(B)(2)
WHEN APP. FOR PERMIT REQ. | 2 | A.103.1,  103.1
DRIVNG ON HIWY CLOSD TO PUBLIC | 2 | 40-6-26.B,  40-6-26(B)
FAILURE TO STOP FOR STOP SIGN | 2 | 40-6-72.B,  40-6-72(B)





















<hr>

## Data Transformation

```` sql
SELECT
  r.id AS row_id
  ,r.endpoint_id
  ,r.guid
  ,r.defendant AS defendant_name

  ,r.violation AS violation_guid
  ,r.description AS violation_desc

  ,r.location AS citation_location
  ,r.payable AS citation_payable

  ,to_date(r.date, 'DD-MON-YY') + TO_TIMESTAMP(r.time, 'HH24:MI:SS')::TIME AS appointment_at
  ,r.room AS appointment_room
FROM atlanta_endpoint_objects r;
````



























<hr>

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

















<hr>
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
