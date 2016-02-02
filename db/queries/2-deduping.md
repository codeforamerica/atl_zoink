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
DROP TABLE if EXISTS temp_violations;
CREATE TABLE temp_violations AS (
  SELECT
    row_number() OVER () AS temp_id
    ,zz.*
  FROM (
    SELECT DISTINCT
      dr.violation AS violation_code
      ,dr.description AS violation_code_description
    FROM atlanta_distinct_objects dr
  ) zz
);
ALTER TABLE temp_violations add PRIMARY key(temp_id);
````

## Querying temp tables


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

```` sql
SELECT tv.*
FROM temp_violations tv
JOIN (
  SELECT
    violation_code
    ,count(DISTINCT violation_code_description) AS description_count
  FROM temp_violations
  GROUP BY 1
  HAVING count(DISTINCT violation_code_description) > 1
  ORDER BY 2 DESC
) dups ON dups.violation_code = tv.violation_code
````

```` sql
SELECT tv.*
FROM temp_violations tv
JOIN (
  SELECT
    violation_code_description
    ,count(DISTINCT violation_code) AS code_count
  FROM temp_violations
  GROUP BY 1
  HAVING count(DISTINCT violation_code) > 1
  ORDER BY 2 DESC
) dups ON dups.violation_code_description = tv.violation_code_description
ORDER BY violation_code_description, violation_code
````

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

There are multiple citations/guids per hearing/appointment:

defendant | appointment_at | appointment_room | citation_id | citation_location | citation_payable | violation_code | violation_code_description | row_id
--- | --- | --- | --- | --- | --- | --- | --- | ---
SESUI, JOHN ROSS | 2014-09-24 08:00:00 | CNVCRT | 4832076 | JUNIPER AT 3RD ST | false,40-6-10. | FAILURE TO MAINTAIN INSURANCE | 3866676
SESUI, JOHN ROSS | 2014-09-24 08:00:00 | CNVCRT | 4832077 | JUNIPER AT 3RD ST | false,40-2-8 | NO TAG/ NO DECAL | 3834475
SESUI, JOHN ROSS | 2014-09-24 08:00:00 | CNVCRT | 4832078 | JUNIPER AT 3RD ST | false,40-5-20 | NO DRIVERS LICENSE | 3861253
SESUI, JOHN ROSS | 2014-09-24 08:00:00 | CNVCRT | 4832799 | JUNIPER AT 3RD ST | true,40-6-181(C) | SPEEDING 11 to 14 MPH OVER | 3845259
SESUI, JOHN ROSS | 2014-09-24 08:00:00 | CNVCRT | 4832800 | JUNIPER AT 3RD ST | false,40-5-29 | FAILURE TO CARRY/EXHIBIT LIC | 3866677

There are multiple violations per citation:

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

#### Violations

There are violation codes with different descriptions, although they are most certainly misspellings.

temp_id | violation_code | violation_code_description
--- | --- | ---
47 | 106-1 | LOITERING AROUND RAILROAD TRKS/SHPS
46 | 106-1 | LOITERING AROUND RAIILROAD TRKS/SHPS
202 | 14-8. | SKATING ON OTHER RINKS PERMIT
201 | 14-8. | SKATING ON OTHER RINKS OERMIT
362 | 162-262 | LOTTERING REQUIRED ON VEHICLE
361 | 162-262 | LETTERING REQUIRED ON VEHICLE


There are violation descriptions with different codes. Some (e.g. "40-6-26(B)" vs "40-6-26.B") look like duplications, but many others perhaps represent different variations/ severities of the same violation.

temp_id | violation_code | violation_code_description
--- | --- | ---
725 | 40-6-294(A) | BICYCLE RIDDEN ON RIGHT SIDE
726 | 40-6-294(B). | BICYCLE RIDDEN ON RIGHT SIDE
29 | 10-9(A)(6) | BOISTEROUS, TURBULENT/AGITATED
32 | 10-9(B)(6) | BOISTEROUS, TURBULENT/AGITATED
457 | 30-1426.C | BUSINESS LICENSE
466 | 30-1481.C | BUSINESS LICENSE
285 | 16-12-4 | CRUELTY TO ANIMALS
394 | 18-5 | CRUELTY TO ANIMALS
25 | 10-9(A)(2) | DEFECATE OR URINATE ON
31 | 10-9(B)(2) | DEFECATE OR URINATE ON
76 | 106-81 | DISORDERLY CONDUCT
371 | 162-42-Q | DISORDERLY CONDUCT
304 | 16-13-32 | DISTRIBUTN OF DRUG RELATED OBJ
305 | 16-13-32.2 | DISTRIBUTN OF DRUG RELATED OBJ
710 | 40-6-26(B) | DRIVNG ON HIWY CLOSD TO PUBLIC
711 | 40-6-26.B | DRIVNG ON HIWY CLOSD TO PUBLIC
885 | 40-8-30 | FAILURE TO DIM HEADLIGHTS
886 | 40-8-31 | FAILURE TO DIM HEADLIGHTS
811 | 40-6-50B | FAILURE TO KEEP IN PROPER LANE
818 | 40-6-53 | FAILURE TO KEEP IN PROPER LANE
575 | 40-6-10. | FAILURE TO MAINTAIN INSURANCE
578 | 40-6-10A | FAILURE TO MAINTAIN INSURANCE
579 | 40-6-10B | FAILURE TO MAINTAIN INSURANCE
828 | 40-6-72(B) | FAILURE TO STOP FOR STOP SIGN
830 | 40-6-72.B | FAILURE TO STOP FOR STOP SIGN
592 | 40-6-123(B) | FAILURE TO USE CORRECT SIGNAL
596 | 40-6-123.B | FAILURE TO USE CORRECT SIGNAL
799 | 40-6-49 | FOLLOWING TOO CLOSELY
800 | 40-6-49(A) | FOLLOWING TOO CLOSELY
803 | 40-6-49B | FOLLOWING TOO CLOSELY
3 | 10-10.A1 | FURNISH ALCOHOL TO PERSON < 21
4 | 10-10.A2 | FURNISH ALCOHOL TO PERSON < 21
5 | 10-10.A3 | FURNISH ALCOHOL TO PERSON < 21
284 | 16-12-21 | GAMBLING
286 | 16-12-CV | GAMBLING
75 | 106-802(A) | GRAFFITI PROHIBITED
952 | 74-174(B)(1) | GRAFFITI PROHIBITED
712 | 40-6-270 | HIT & RUN/FAIL TO RENDER AID
713 | 40-6-270(A) | HIT & RUN/FAIL TO RENDER AID
591 | 40-6-123(A) | IMPROPER LANE CHANGE
595 | 40-6-123.A | IMPROPER LANE CHANGE
651 | 40-6-203(A) | IMPROPER STOPPING ON ROADWAY
652 | 40-6-203(A)(1)(A) | IMPROPER STOPPING ON ROADWAY
668 | 40-6-203(A)1 | IMPROPER STOPPING ON ROADWAY
676 | 40-6-203.B | IMPROPER STOPPING ON ROADWAY
677 | 40-6-203.C | IMPROPER STOPPING ON ROADWAY
739 | 40-6-315(A) | NO HELMET
741 | 40-6-315.A | NO HELMET
366 | 162-42-5 | NO INSURANCE
572 | 40-6-10(A)(1) | NO INSURANCE
389 | 18-129 | NUISANCES
950 | 74-161 | NUISANCES
576 | 40-6-10.A | OPERATE VEH WITHOUT INSURANCE
577 | 40-6-10.B | OPERATE VEH WITHOUT INSURANCE
788 | 40-6-45(A) | PASSING ON HILL OR CURVE
789 | 40-6-45(A)1 | PASSING ON HILL OR CURVE
783 | 40-6-43(B) | PASSING ON SHOULDER OF ROAD
784 | 40-6-43.B | PASSING ON SHOULDER OF ROAD
293 | 16-13-30 | POSS/MANU/ETC. CONTROL SUB
294 | 16-13-30(A) | POSS/MANU/ETC. CONTROL SUB
295 | 16-13-30(B) | POSS/MANU/ETC. CONTROL SUB
296 | 16-13-30(J) | POSS/MANU/ETC. CONTROL SUB
297 | 16-13-30(J)(1) | POSS/MANU/ETC. CONTROL SUB
298 | 16-13-30(J)(2) | POSS/MANU/ETC. CONTROL SUB
446 | 3-3-23.1 | POSSESSION ALCOHOL BY MINOR
447 | 3-3-23A2C | POSSESSION ALCOHOL BY MINOR
291 | 16-13-2(B) | POSSESSION OF MARIJUANA
292 | 16-13-2B | POSSESSION OF MARIJUANA
995 | 8-2095(4) | POSTING OF ASSIGNED NUMBERS
1054 | E.28 | POSTING OF ASSIGNED NUMBERS
8 | 10-2003 | PROHIB CONDUCT IN PARK
119 | 110-59 | PROHIB CONDUCT IN PARK
24 | 10-9(A)(1) | RECKLESS MANNER/UNREAS RISK
30 | 10-9(B)(1) | RECKLESS MANNER/UNREAS RISK
666 | 40-6-203(A)(2)(F) | RESTRICTED PARKING
1060 | PK02 | RESTRICTED PARKING
319 | 16-28A.007 | SIGN GENERAL REGULATIONS
322 | 16-28A.012 | SIGN GENERAL REGULATIONS
957 | 74-42(E)(3) | STOPWORK FOR IMMINENT THREAT TO PUBLIC HEALTH/ STATE WORKERS
960 | 74-42(F)(3) | STOPWORK FOR IMMINENT THREAT TO PUBLIC HEALTH/ STATE WORKERS
409 | 22-204 | UNLAWFUL CONDUCT PROHIB. A/P
410 | 22-204(2) | UNLAWFUL CONDUCT PROHIB. A/P
348 | 162-117 | USE OF OPEN STAND
350 | 162-117.B | USE OF OPEN STAND
40 | 103.1 | WHEN APP. FOR PERMIT REQ.
1002 | A.103.1 | WHEN APP. FOR PERMIT REQ.
