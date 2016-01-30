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

> NOTE: the findings below result from queries run on local database (macbook air) ...

The full table of extracted objects is large and slow to query. And indexing may not be an applicable solution.

```` sql
SELECT count(DISTINCT id) FROM atlanta_endpoint_objects; -- > 6,734,949 rows; 6,520 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; -- > 390,831 rows; 231,604 ms
CREATE INDEX guid_index ON atlanta_endpoint_objects (guid); -- > 230,836 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; -- > 390,831 rows; 243,083 ms
````

### Summary Statistics and Findings

```` sql
SELECT count(DISTINCT id) FROM atlanta_endpoint_objects; --> 6,734,949 rows; 6,520 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; --> 390,831 rows; 243,083 ms
SELECT count(DISTINCT violation) FROM atlanta_endpoint_objects; --> 1,054 rows; 177,763 ms
SELECT count(DISTINCT description) FROM atlanta_endpoint_objects; --> 1,009 rows; 203,546 ms
SELECT count(DISTINCT defendant) FROM atlanta_endpoint_objects; --> 266,159 rows; 272,806 ms
SELECT count(DISTINCT location) FROM atlanta_endpoint_objects; --> 149,025 rows; 265,849 ms
SELECT count(DISTINCT room) FROM atlanta_endpoint_objects; --> 17 rows; 39,646 ms
-- ... such few rooms probably refer to the same building ... but which one?
SELECT count(DISTINCT time) FROM atlanta_endpoint_objects; --> 37 rows; 46,182 ms
````

#### Payables

```` sql
SELECT
  count(DISTINCT CASE WHEN payable = TRUE THEN guid end) AS payable_citation_count
  ,count(DISTINCT CASE WHEN payable = FALSE THEN guid end) AS nonpayable_citation_count
  ,count(DISTINCT CASE WHEN payable IS NULL THEN guid end) AS nullpayable_citation_count
  ,count(DISTINCT CASE WHEN payable = TRUE THEN guid end)
    * 1.00 -- hack decimal precision
    / count(DISTINCT guid) AS payable_citation_percentage

  ,count(DISTINCT CASE WHEN payable = TRUE THEN id end) AS payable_appt_count
  ,count(DISTINCT CASE WHEN payable = FALSE THEN id end) AS nonpayable_appt_count
  ,count(DISTINCT CASE WHEN payable IS NULL THEN id end) AS nullpayable_appt_count
  ,count(DISTINCT CASE WHEN payable = TRUE THEN id end)
    * 1.00 -- hack decimal precision
    / count(DISTINCT id) AS payable_appt_percentage
FROM atlanta_endpoint_objects; -- > 484,133 ms
````

=>

payable_citation_count | nonpayable_citation_count | nullpayable_citation_count | payable_citation_percentage | payable_appt_count | nonpayable_appt_count | nullpayable_appt_count | payable_appt_percentage
--- | --- | --- | --- | --- | --- | --- | ---
228635 | 166649 | 0 | 0.58499709593149 | 3206357 | 3528592 | 0 | 0.476077398655877


... 58.5% of the citations vs 47.6% of the appointments are payable.




#### Appointment Times and Room Numbers

```` sql
-- how many appointments per time?
SELECT
  TO_TIMESTAMP(time, 'HH24:MI:SS AM')::TIME AS appointment_time
  ,count(DISTINCT id) AS row_count
FROM atlanta_endpoint_objects
GROUP BY 1
ORDER BY 1; -- > 27,645 ms
````

=>

appointment_time | row_count
--- | ---
00:00:00 | 10
01:00:00 | 956
01:10:00 | 2
01:30:00 | 5
01:50:00 | 7
03:00:00 | 384
03:15:00 | 27
05:00:00 | 9
08:00:00 | 3273610
08:10:00 | 40
08:11:00 | 28
08:30:00 | 217
09:00:00 | 64447
09:16:00 | 44
09:30:00 | 158
10:00:00 | 667395
10:10:00 | 9
10:12:00 | 92
10:29:00 | 48
10:30:00 | 3
11:00:00 | 907364
11:19:00 | 54
11:30:00 | 22
12:00:00 | 8
12:19:00 | 15
12:30:00 | 6
13:00:00 | 376269
13:30:00 | 60
14:00:00 | 10033
14:20:00 | 12
14:30:00 | 3
15:00:00 | 1433440
16:00:00 | 22
17:00:00 | 100
18:00:00 | 25
19:00:00 | 24
20:14:00 | 1

```` sql
-- how many appointments per room?
SELECT
  room
  ,count(DISTINCT id) AS row_count
FROM atlanta_endpoint_objects
GROUP BY 1
ORDER BY 1; -- > 51,008 ms
````

=>

room | row_count
--- | ---
 | 880
1A | 346332
1B | 83084
3A | 214696
3B | 433053
5A | 808703
5B | 393118
5C | 552778
5D | 179675
6A | 383304
6B | 462149
6C | 525780
6D | 741947
CNVCRT | 1141476
JAIL | 89
JRYASM | 432682
MIX | 35203

... null room numbers for 880 appointments. :-/


```` sql
-- how many appointments per room and time combination?
SELECT
  room
  ,TO_TIMESTAMP(time, 'HH24:MI:SS AM')::TIME AS appointment_time
  ,count(DISTINCT id) AS row_count
FROM atlanta_endpoint_objects
GROUP BY 1,2
ORDER BY 1,2 DESC
; -- > 56,833 ms
````

=>

room | appointment_time | row_count
--- | --- | ---
 | 15:00:00 | 237
 | 13:00:00 | 42
 | 11:00:00 | 145
 | 10:00:00 | 237
 | 09:00:00 | 18
 | 08:00:00 | 201
1A | 15:00:00 | 10111
1A | 13:00:00 | 25848
1A | 11:00:00 | 256985
1A | 10:00:00 | 29207
1A | 09:00:00 | 17
1A | 08:30:00 | 129
1A | 08:00:00 | 24015
1A | 03:00:00 | 1
1A | 01:00:00 | 19
1B | 16:00:00 | 22
1B | 15:00:00 | 40713
1B | 13:00:00 | 40141
1B | 11:00:00 | 158
1B | 10:00:00 | 1747
1B | 09:00:00 | 56
1B | 08:00:00 | 137
1B | 01:00:00 | 110
3A | 15:00:00 | 3654
3A | 13:30:00 | 60
3A | 13:00:00 | 1259
3A | 11:00:00 | 35279
3A | 10:00:00 | 2219
3A | 09:00:00 | 197
3A | 08:00:00 | 172028
3B | 18:00:00 | 23
3B | 15:00:00 | 70305
3B | 14:00:00 | 90
3B | 13:00:00 | 31705
3B | 12:30:00 | 6
3B | 11:30:00 | 16
3B | 11:00:00 | 4393
3B | 10:12:00 | 92
3B | 10:00:00 | 158523
3B | 09:30:00 | 158
3B | 09:00:00 | 4392
3B | 08:30:00 | 86
3B | 08:11:00 | 28
3B | 08:00:00 | 163226
3B | 01:30:00 | 5
3B | 01:00:00 | 5
5A | 15:00:00 | 53796
5A | 14:00:00 | 2189
5A | 13:00:00 | 9980
5A | 11:00:00 | 315
5A | 10:30:00 | 3
5A | 10:29:00 | 48
5A | 10:00:00 | 2661
5A | 09:00:00 | 117
5A | 08:00:00 | 739556
5A | 03:00:00 | 22
5A | 01:00:00 | 16
5B | 17:00:00 | 1
5B | 15:00:00 | 224512
5B | 14:00:00 | 129
5B | 13:00:00 | 51252
5B | 11:19:00 | 54
5B | 10:00:00 | 1135
5B | 09:16:00 | 12
5B | 09:00:00 | 282
5B | 08:00:00 | 115573
5B | 03:00:00 | 168
5C | 17:00:00 | 99
5C | 15:00:00 | 54682
5C | 14:00:00 | 2046
5C | 13:00:00 | 28433
5C | 12:19:00 | 15
5C | 11:00:00 | 172419
5C | 10:00:00 | 150654
5C | 09:00:00 | 820
5C | 08:00:00 | 143224
5C | 01:00:00 | 386
5D | 15:00:00 | 65688
5D | 14:00:00 | 336
5D | 13:00:00 | 1513
5D | 11:00:00 | 4628
5D | 10:00:00 | 538
5D | 09:00:00 | 52
5D | 08:00:00 | 106920
6A | 15:00:00 | 32088
6A | 14:00:00 | 1
6A | 13:00:00 | 778
6A | 11:30:00 | 6
6A | 11:00:00 | 109
6A | 10:10:00 | 9
6A | 10:00:00 | 63965
6A | 09:00:00 | 3
6A | 08:30:00 | 2
6A | 08:00:00 | 286262
6A | 03:00:00 | 12
6A | 01:00:00 | 69
6B | 19:00:00 | 24
6B | 15:00:00 | 220919
6B | 14:30:00 | 3
6B | 14:20:00 | 12
6B | 14:00:00 | 119
6B | 13:00:00 | 123194
6B | 11:00:00 | 213
6B | 10:00:00 | 936
6B | 09:16:00 | 32
6B | 09:00:00 | 58120
6B | 08:00:00 | 58237
6B | 03:00:00 | 1
6B | 01:00:00 | 329
6B | 00:00:00 | 10
6C | 15:00:00 | 64706
6C | 14:00:00 | 104
6C | 13:00:00 | 3281
6C | 12:00:00 | 8
6C | 11:00:00 | 8
6C | 10:00:00 | 112642
6C | 09:00:00 | 232
6C | 08:00:00 | 344797
6C | 01:00:00 | 2
6D | 20:14:00 | 1
6D | 15:00:00 | 75698
6D | 14:00:00 | 5019
6D | 13:00:00 | 12599
6D | 11:00:00 | 31
6D | 10:00:00 | 104933
6D | 09:00:00 | 141
6D | 08:10:00 | 40
6D | 08:00:00 | 543447
6D | 05:00:00 | 9
6D | 03:00:00 | 12
6D | 01:10:00 | 2
6D | 01:00:00 | 15
CNVCRT | 18:00:00 | 2
CNVCRT | 15:00:00 | 495735
CNVCRT | 13:00:00 | 45448
CNVCRT | 10:00:00 | 37206
CNVCRT | 08:00:00 | 562917
CNVCRT | 03:00:00 | 163
CNVCRT | 01:00:00 | 5
JAIL | 15:00:00 | 28
JAIL | 13:00:00 | 2
JAIL | 10:00:00 | 16
JAIL | 08:00:00 | 43
JRYASM | 13:00:00 | 1
JRYASM | 11:00:00 | 432681
MIX | 15:00:00 | 20568
MIX | 13:00:00 | 793
MIX | 10:00:00 | 776
MIX | 08:00:00 | 13027
MIX | 03:15:00 | 27
MIX | 03:00:00 | 5
MIX | 01:50:00 | 7












#### Duplicate Violation Descriptions

Some violations have the same exact description but different identifiers...

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

Some violations most likely refer to the same thing, but are worded differently (e.g. `'FAILURE TO YIELD TO PEDESTRIAN AT CROSSWALK'` vs `'YTD TO PEDESTRIAN IN CROSSWALK'`).


#### Violation Categories

> NOTE: categorization is in progress ... https://github.com/kuanb/atl_zoink/issues/9

```` sql
/*
SELECT description FROM violations WHERE description LIKE '%ZONING%' ORDER BY description;
*/

SELECT *
FROM (
  SELECT
    -- v.id AS violation_id
    -- ,v.guid AS violation_guid
    v.description AS violation_description
    ,CASE
      WHEN v.description = 'ZONING VIOLATION'
        THEN 'HOUSING AND BUSINESS'
      WHEN v.description LIKE '%YIELD%'
        OR v.description = 'YTD TO PEDESTRIAN IN CROSSWALK'
        OR v.description = 'PARKING OF COMMERCIAL TRLR PROHIBITED IN CERTAIN ZONING DISTRICTS'
        THEN 'DRIVING'
      WHEN v.description = 'PEDESTRIAN DARTING OUT IN TRAFFIC'
        OR v.description = 'PEDESTRIAN OBSTRUCTING TRAFFIC'
        OR v.description = 'FAILURE TO YIELD TO PEDESTRIAN AT CROSSWALK'
        THEN 'PEDESTRIANISM'


      ELSE 'TODO'
    END violation_category
  FROM violations v
  ORDER BY violation_category, violation_description DESC
) categorizations
WHERE violation_category = 'TODO'
````























































































> STOP READING HERE FOR NOW.

<hr>
<hr>
<hr>
<hr>
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
