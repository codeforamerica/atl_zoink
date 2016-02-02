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

There are also many instances of multiple simultaneous appointments for the same defendant and citation_id but in different rooms. This is most likely an error or an update to the room.

### Citations

```` sql
SELECT
 dr.defendant

 ,to_date(dr.date, 'DD-MON-YY') + TO_TIMESTAMP(dr.time, 'HH24:MI:SS')::TIME AS appointment_at
 ,dr.room AS appointment_room

 ,dr.guid AS citation_id
 ,dr.location AS citation_location
 ,dr.payable AS citation_payable

 ,dr.violation AS violation_code
 ,dr.description AS violation_code_description

 ,dr.min_object_id AS row_id

FROM atlanta_distinct_objects dr
ORDER BY defendant, appointment_at, citation_id
````

There are multiple citations/guids per hearing/appointment:

defendant | appointment_at | appointment_room | citation_id | citation_location | citation_payable | violation_code | violation_code_description | row_id
--- | --- | --- | --- | --- | --- | --- | --- | ---
SESUI, JOHN ROSS | 2014-09-24 08:00:00 | CNVCRT | 4832076 | JUNIPER AT 3RD ST | false,40-6-10. | FAILURE TO MAINTAIN INSURANCE | 3866676
SESUI, JOHN ROSS | 2014-09-24 08:00:00 | CNVCRT | 4832077 | JUNIPER AT 3RD ST | false,40-2-8 | NO TAG/ NO DECAL | 3834475
SESUI, JOHN ROSS | 2014-09-24 08:00:00 | CNVCRT | 4832078 | JUNIPER AT 3RD ST | false,40-5-20 | NO DRIVERS LICENSE | 3861253
SESUI, JOHN ROSS | 2014-09-24 08:00:00 | CNVCRT | 4832799 | JUNIPER AT 3RD ST | true,40-6-181(C) | SPEEDING 11 to 14 MPH OVER | 3845259
SESUI, JOHN ROSS | 2014-09-24 08:00:00 | CNVCRT | 4832800 | JUNIPER AT 3RD ST | false,40-5-29 | FAILURE TO CARRY/EXHIBIT LIC | 3866677


multiple violations per citation:

defendant | appointment_at | appointment_room | citation_id | citation_location | citation_payable | violation_code | violation_code_description | row_id
--- | --- | --- | --- | --- | --- | --- | --- | ---
BORDERS, JUSTIN PAUL | 2015-06-11 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | true | 40-6-20 | FAIL TO OBEY TRAF CTRL DEVICE | 250827
BORDERS, JUSTIN PAUL | 2015-08-04 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | true | 40-6-20 | FAIL TO OBEY TRAF CTRL DEVICE | 217096
BORDERS, JUSTIN PAUL | 2015-10-22 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | true | 40-6-20 | FAIL TO OBEY TRAF CTRL DEVICE | 123322
BORDERS, JUSTIN PAUL | 2015-09-24 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | true | 40-6-20 | FAIL TO OBEY TRAF CTRL DEVICE | 157371
BORDERS, JUSTIN PAUL | 2015-11-17 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | true | 40-6-20 | FAIL TO OBEY TRAF CTRL DEVICE | 73733
BORDERS, JUSTIN PAUL | 2015-11-17 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391(A)3 | DUI-INHALENTS (40-6-391(A)3) | 98166
BORDERS, JUSTIN PAUL | 2015-09-24 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391(A)3 | DUI-INHALENTS (40-6-391(A)3) | 148866
BORDERS, JUSTIN PAUL | 2015-08-04 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391(A)3 | DUI-INHALENTS (40-6-391(A)3) | 240708
BORDERS, JUSTIN PAUL | 2015-10-22 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391(A)3 | DUI-INHALENTS (40-6-391(A)3) | 131881
BORDERS, JUSTIN PAUL | 2015-06-11 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391(A)3 | DUI-INHALENTS (40-6-391(A)3) | 246339
BORDERS, JUSTIN PAUL | 2015-09-24 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391(A)5 | D.U.I. PERSON CONCENTRATION (40-6-391(A)5) | 136204
BORDERS, JUSTIN PAUL | 2015-06-11 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391(A)5 | D.U.I. PERSON CONCENTRATION (40-6-391(A)5) | 273399
BORDERS, JUSTIN PAUL | 2015-11-17 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391(A)5 | D.U.I. PERSON CONCENTRATION (40-6-391(A)5) | 98167
BORDERS, JUSTIN PAUL | 2015-08-04 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391(A)5 | D.U.I. PERSON CONCENTRATION (40-6-391(A)5) | 235937
BORDERS, JUSTIN PAUL | 2015-10-22 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391(A)5 | D.U.I. PERSON CONCENTRATION (40-6-391(A)5) | 127565
BORDERS, JUSTIN PAUL | 2015-11-17 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A1 | D.U.I./ALCOHOL (40-6-391.A1) | 77767
BORDERS, JUSTIN PAUL | 2015-06-11 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A1 | D.U.I./ALCOHOL (40-6-391.A1) | 264308
BORDERS, JUSTIN PAUL | 2015-09-24 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A1 | D.U.I./ALCOHOL (40-6-391.A1) | 140300
BORDERS, JUSTIN PAUL | 2015-08-04 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A1 | D.U.I./ALCOHOL (40-6-391.A1) | 217097
BORDERS, JUSTIN PAUL | 2015-10-22 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A1 | D.U.I./ALCOHOL (40-6-391.A1) | 127563
BORDERS, JUSTIN PAUL | 2015-10-22 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A2 | D.U.I./DRUGS (40-6-391.A2) | 127564
BORDERS, JUSTIN PAUL | 2015-08-04 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A2 | D.U.I./DRUGS (40-6-391.A2) | 231165
BORDERS, JUSTIN PAUL | 2015-09-24 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A2 | D.U.I./DRUGS (40-6-391.A2) | 165910
BORDERS, JUSTIN PAUL | 2015-06-11 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A2 | D.U.I./DRUGS (40-6-391.A2) | 273398
BORDERS, JUSTIN PAUL | 2015-11-17 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A2 | D.U.I./DRUGS (40-6-391.A2) | 69682
BORDERS, JUSTIN PAUL | 2015-10-22 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A4 | DUI - MULTIPLE SUBSTANCES-MISD (40-6-391.A4) | 114835
BORDERS, JUSTIN PAUL | 2015-11-17 08:00:00 | 3A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A4 | DUI - MULTIPLE SUBSTANCES-MISD (40-6-391.A4) | 73734
BORDERS, JUSTIN PAUL | 2015-09-24 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A4 | DUI - MULTIPLE SUBSTANCES-MISD (40-6-391.A4) | 161689
BORDERS, JUSTIN PAUL | 2015-06-11 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A4 | DUI - MULTIPLE SUBSTANCES-MISD (40-6-391.A4) | 255413
BORDERS, JUSTIN PAUL | 2015-08-04 08:00:00 | 5A | E01838224 | MLK DR AT JESSIE HILL JR DR | false | 40-6-391.A4 | DUI - MULTIPLE SUBSTANCES-MISD (40-6-391.A4) | 226423

And upon second look, too many of the instances of multiple defendants per citation look like misspellings to consider there being multiple defendants per citation.


```` sql
SELECT
 yy.citation_id, dr.defendant, dr.location, dr.violation, dr.description, dr.payable, dr.date
FROM (
 SELECT
   citation_id
   ,count(DISTINCT defendant) AS defendant_count
 FROM (
   SELECT
     dr.defendant

     ,to_date(dr.date, 'DD-MON-YY') + TO_TIMESTAMP(dr.time, 'HH24:MI:SS')::TIME AS appointment_at
     ,dr.room AS appointment_room

     ,dr.guid AS citation_id
     ,dr.location AS citation_location
     ,dr.payable AS citation_payable

     ,dr.violation AS violation_code
     ,dr.description AS violation_code_description

     ,dr.min_object_id AS row_id
   FROM atlanta_distinct_objects dr
   ORDER BY citation_id, defendant, violation_code
 ) zz
 GROUP BY 1
 HAVING count(DISTINCT defendant) > 1
) yy
JOIN atlanta_distinct_objects dr ON yy.citation_id = dr.guid
ORDER BY citation_id, defendant
