# Queries

## De-duplicating rows

run on a local backup copy of the production database:

```` sql
DROP TABLE if EXISTS atlanta_distinct_objects;
CREATE TABLE atlanta_distinct_objects AS (
  SELECT
    guid
    ,location
    ,payable
    ,defendant
    ,r.date
    ,r.time
    ,r.room
    ,r.violation
    ,r.description
    ,count(DISTINCT r.id) AS object_count
    ,min(r.id) AS min_object_id
    ,max(r.id) AS max_object_id
  FROM atlanta_endpoint_objects r
  GROUP BY 1,2,3,4,5,6,7,8,9
  ORDER BY r.guid, r.date
);
ALTER TABLE atlanta_distinct_objects ADD PRIMARY KEY (min_object_id);
CREATE INDEX guid_index ON atlanta_distinct_objects (guid);
````

This brings the row count down from ~7M to ~800K and should speed up further investigation and transformation queries.


## Creating temp tables

```` sql
DROP TABLE if EXISTS temp_timeslots;
CREATE TABLE temp_timeslots AS (
  SELECT
    row_number() OVER () AS temp_id
    ,zz.*
  FROM (
    SELECT DISTINCT
      dr.date
      ,dr.time
      ,dr.room
    FROM atlanta_distinct_objects dr
  ) zz
);
ALTER TABLE temp_timeslots add primary key(temp_id);
````

```` sql
DROP TABLE if EXISTS temp_appts;
CREATE TABLE temp_appts AS (
  SELECT
    row_number() OVER () AS temp_id
    ,zz.*
  FROM (
    SELECT DISTINCT
      dr.date
      ,dr.time
      ,dr.room
      ,dr.defendant
    FROM atlanta_distinct_objects dr
  ) zz
);
ALTER TABLE temp_appts add primary key(temp_id);
````

```` sql
SELECT
  guid
  ,count(DISTINCT temp_id) AS timeslot_count
FROM atlanta_distinct_objects dr
JOIN temp_timeslots tt ON tt.date = dr.date AND tt.time = dr.time AND dr.room = tt.room
GROUP BY 1
HAVING count(DISTINCT temp_id) > 1
````

```` sql
SELECT
  guid
  ,count(DISTINCT temp_id) AS appointment_count
FROM atlanta_distinct_objects dr
JOIN temp_appts ta ON ta.date = dr.date AND ta.time = dr.time AND dr.room = ta.room AND ta.defendant = dr.defendant
GROUP BY 1
HAVING count(DISTINCT temp_id) > 1
````

```` sql
SELECT
  tt.temp_id
  ,count(DISTINCT dr.guid) AS citation_count
FROM temp_timeslots tt
JOIN atlanta_distinct_objects dr ON tt.date = dr.date AND tt.time = dr.time AND dr.room = tt.room
GROUP BY 1
HAVING count(DISTINCT dr.guid) > 1
````

```` sql
SELECT
  ta.temp_id
  ,count(DISTINCT dr.guid) AS citation_count
FROM temp_appts ta
JOIN atlanta_distinct_objects dr ON ta.date = dr.date AND ta.time = dr.time AND dr.room = ta.room AND ta.defendant = dr.defendant
GROUP BY 1
HAVING count(DISTINCT dr.guid) > 1
````

<hr>



## Re-exploring with new datasets

### Guids

There are 407,328 distinct `guid` values in the new dataset.

 + 4,556 / 407,328 `guid` have more than one `payable` value (1.1%)
 + 830 / 407,328 `guid` have more than one `location` value (0.2%)
 + 3,132 / 407,328 `guid` have more than one `defendant` value (0.7%)
 + 1,2668 / 407,328 `guid` have more than one `violation` value (0.3%)
 + 194,039 / 407,328 `guid` have more than one (`date`, `time`, `room`) value combination (47.6%)
 + 194,546 / 407,328 `guid` have more than one (`date`, `time`, `room`, `defendant`) value combination (47.7%)

### Timeslots

There are 12,642 distinct timeslots (`date` x `time` x `room` combos) in the new dataset.

 + 11,130 / 12,642 timeslots have more than one `guid` value (88.0%)

### Appointments

There are 557,106 distinct appointments (`date` x `time` x `room` x `defendant` combos) in the new dataset.

 + 109,101 / 557,106 appointments have more than one `guid` value (19.6%)
