# Queries

## Exploring

### Row Structure

```` sql
-- what's the deal with guid values? what do they describe/identify exactly?

SELECT
  MIN(record_count) AS min_records
  ,max(record_count) AS max_records
  ,MIN(defendant_count) AS min_defendants
  ,max(defendant_count) AS max_defentants
  ,min(location_count) AS min_locations
  ,MAX(location_count) AS max_locations
  ,MIN(violation_code_count) AS min_violation_codes
  ,max(violation_code_count) AS max_violation_codes
FROM (
  SELECT
    r.guid
    ,count(DISTINCT r.id) AS record_count
    -- ,count(DISTINCT r.endpoint_id) AS datasource_count
    ,count(DISTINCT r.defendant) AS defendant_count
    ,count(DISTINCT r.location) AS location_count
    ,count(DISTINCT r.violation) AS violation_code_count
    -- ,count(DISTINCT r.description) AS violation_desc_count
    -- ,count(DISTINCT r.payable) AS payable_count
  FROM atlanta_endpoint_objects r
  GROUP BY 1
  ORDER BY 2 DESC
) counts
````
=>

min_records | max_records | min_defendants | max_defentants | min_locations | max_locations | min_violation_codes | max_violation_codes
--- | --- | --- | --- | --- | --- | --- | ---
1 | 1250 | 1 | 4 | 1 | 3 | 1 | 15

Each `guid` corresponds to:
  + between 1 and 1250 records
  + between 1 and a few hundred different data sources (urls)
  + between 1 and 4 different `defendant` values
  + between 1 and 3 different `location` values
  + between 1 and 15 different `violation` code and `description` values
  + between 1 and 2 different `payable` values

#### Multiple Defendants per GUID

```` sql
-- how many guid values have more than one defendant?
SELECT count(DISTINCT guid)
FROM (
  SELECT
    r.guid
    ,count(DISTINCT defendant) AS defendant_count
  FROM atlanta_endpoint_objects r
  GROUP BY 1
  HAVING count(DISTINCT defendant) > 1
  ORDER BY 2 DESC
) dups; -- > 3,131 / 407,118 * 100 = 0.77%
````

```` sql
-- what's going on with guid values that have more than one defendant?
SELECT
  uniqs.guid
  ,uniqs.defendant
  ,dups.defendant_count
FROM (
  SELECT guid, count(distinct defendant) as defendant_count
  FROM atlanta_endpoint_objects
  GROUP BY 1
  HAVING count(distinct defendant) > 1
  ORDER BY 1
) dups
JOIN (
  SELECT distinct guid, defendant FROM atlanta_endpoint_objects
) uniqs ON dups.guid = uniqs.guid
ORDER BY 3,2;
````

=> (sample)

guid | defendant | defendant_count
--- | --- | ---
APD | ARELLANO, JESUS M | 4
APD | BRUNSON, NATHANIEL | 4
APD | MCLIA, GRESELDA D | 4
APD | ROBINSON, LINDSEY E | 4
4756923 | MARTINEZ, JOB R | 3
4756923 | MARTINEZ, ROB | 3
4756923 | MILLER, LAURA E | 3
4757591 | JONES, JOHN W | 3
4757591 | JONES, TONY E | 3
4757591 | JONES, VICTORIA MYERS | 3
4847529 | LAUTH, THOMAS P. | 3
4847529 | MACK, APRIL | 3
4847529 | MOCK, APRIL LAVONNE | 3
4974920 | KLINGENBECK, JOHN BROOKS | 3
4974920 | KLINGENBECK, JOSEPH HERMAN | 3
4974920 | WINGENBACK, JOHN BROOKS | 3
5017176 | HOSSEINZADEH-ZARIBAF, MARYAM NAZ | 3
5017176 | HOSSEINZADEH-ZARIBAF, MARYAN | 3
5017176 | WILLIAMS, TRIONTA D | 3
5017959 | FINK, AAVAN S | 3
5017959 | FLOURNEY, CHIRSTOPER O | 3
5017959 | FLOURNOY, CHRISTOPHER O | 3
5023426 | JAMELL, DARRYL A | 3
5023426 | JAMELL, DARRYL A. MINOR | 3
5023426 | MINOR, DARRYL J | 3
000052 | CARTER, JEFFERY CURTIS | 2
000052 | GREEN, TERRY | 2
000053 | ABRAHAM, LENNDRE T | 2
000053 | CARTER, JEFFREY | 2
0002896 | KING, ASIA MONAE | 2
0002896 | KINS, ASIA MONAE | 2
034298 | FAULK, PHILLIP CHRISTOPHER | 2
034298 | FAWLK, PHILLIP CHRISTOPHER | 2
034869 | JOSEPH, SOLANGE | 2
034869 | JOSEPH, SOLANIA | 2
037578 | WILKINS, MINIFA A | 2
037578 | WILKINS, MONIFA A | 2
037709 | VANAS, SARAH BELL | 2
037709 | VONGS, SARAH BELL | 2
037716 | HAMM, MONICA C | 2
037716 | MCCABE, SEAN MICHAEL | 2
038101 | KEEMAR, RISHI | 2
038101 | KUMAR, RISHI | 2
039509 | BENSON, EARNEST T | 2
039509 | BENSON, ZORNEST T | 2
039755 | KESSLER, RANDALL MARK | 2
039755 | KESSLER, RANDELL MARK | 2
09302014 | MCLAWHORN, JOSHUA D | 2
09302014 | SANCHEZ, CHRISTOPHER D | 2
111995 | LAIR, DONALD RAY | 2
111995 | YOUNG, PIERRE LAMON | 2
112561 | MORTOAN, KEENAN | 2
112561 | MORTON, KEENAN | 2
118131 | WALKER, GERALD | 2
118131 | WALKER, GERLAD | 2
122819 | SMITH, EMMANUEL L | 2
122819 | SMITH, LAMONT | 2
124768 | DAVEN, RICHARDSON COSBY | 2
124768 | RICHARDSON, DAVEN COSBY | 2
128936 | ALUKO, ADETOKUBO A | 2
128936 | ALUKO, ADETOKVNBO A. | 2
129386 | CAMPBELL, QUINN | 2
129386 | CAMPBELL, QYINN PADGETT | 2
129431 | HILL, QUINTON MARTEL | 2

... some look like clear spelling errors while others don't. In the latter case, are these instances of multiple people getting included in the same citation, or are they instances of the same person giving false information?

Either way this data is dirty and needs person identifiers.

#### Multiple Violations per GUID

```` sql
-- how many guid values have more than one violation?
SELECT count(DISTINCT guid)
FROM (
  SELECT
    r.guid
    ,count(DISTINCT violation) AS violation_count
  FROM atlanta_endpoint_objects r
  GROUP BY 1
  HAVING count(DISTINCT violation) > 1
  ORDER BY 2 DESC
) dups; -- > 12,634 / 407,118 * 100 = 3.1%
````

```` sql
-- what's going on with guid values that have more than one violation?
SELECT
  uniqs.guid
  ,uniqs.violation
  ,dups.violation_count
FROM (
  SELECT guid, count(distinct violation) as violation_count
  FROM atlanta_endpoint_objects
  GROUP BY 1
  HAVING count(distinct violation) > 1
  ORDER BY 1
) dups
JOIN (
  SELECT distinct guid, violation FROM atlanta_endpoint_objects
) uniqs ON dups.guid = uniqs.guid
ORDER BY 1,2;
````

=> (sample)

guid | violation | description | violation_count
--- | --- | --- | ---
1662494 | 106-7 | PASSENG/STATION COND/RULES | 2
1662494 | 106-85. | MONETARY SOLICITATION | 2
1734307 | 10-9.B1 | DWI RECKLESS CONDUCT | 2
1734307 | 10-9.B6 | DWI PROF/ABUS LANG | 2
1735958 | 106-81.3 | DC SECTION 3 - FIGHTING | 2
1735958 | 16-13-2(B) | POSSESSION OF MARIJUANA | 2
1735976 | 106-81.1 | DC SEC 1-ACT VIOLENT W/ANOTHER | 2
1735976 | 10-9 | DISORDERLY WHILE UNDER INFLUEN | 2
1748599 | 106-81.3 | DC SECTION 3 - FIGHTING | 2
1748599 | 106-84 | DISORDERLY AT SCHOOL | 2
1750030 | 16-8-14 | THEFT BY SHOPLIFTING | 2
1750030 | WARRANT-CR | CRIMINAL WARRANT | 2
1754712 | 106-81(7) | DC SEC 7-PHYSICAL OBSTRUCT ANOTHER | 2
1754712 | 10-9 | DISORDERLY WHILE UNDER INFLUEN | 2
4775442 | 40-8-25 | BRAKE LIGHTS REQUIRED | 2
4775442 | 40-8-76.1 | SAFETY BELT VIOLATION | 2
4775826 | 40-6-70 | FAIL TO YLD TO VEH ON RIGHT | 2
4775826 | 40-6-73 | FAIL TO YIELD RIGHT OF WAY WHILE ENTER ROADWAY | 2
4775966 | 40-6-181(D) | SPEEDING 15 to 18 MPH OVER | 2
4775966 | 40-8-25 | BRAKE LIGHTS REQUIRED | 2
4776331 | 40-5-33 | 60 DAYS TO CHANGE ADDRESS | 2
4776331 | 40-8-73.1 | IMPROPER WINDOW TINTING | 2
4776533 | 40-6-20 | FAIL TO OBEY TRAF CTRL DEVICE | 2
4776533 | 40-8-76.1 | SAFETY BELT VIOLATION | 2
E01414583 | 40-6-391.A1 | D.U.I./ALCOHOL (40-6-391.A1) | 5
E01414583 | 40-6-391.A2 | D.U.I./DRUGS (40-6-391.A2) | 5
E01414583 | 40-6-391.A3 | D.U.I./ALCOHOL & DRUGS (40-6-391.A3) | 5
E01414583 | 40-6-391.A4 | DUI - MULTIPLE SUBSTANCES-MISD (40-6-391.A4) | 5
E01414583 | 40-6-391(A)5 | D.U.I. PERSON CONCENTRATION (40-6-391(A)5) | 5
E01418132 | 40-6-391.A1 | D.U.I./ALCOHOL (40-6-391.A1) | 5
E01418132 | 40-6-391.A2 | D.U.I./DRUGS (40-6-391.A2) | 5
E01418132 | 40-6-391.A3 | D.U.I./ALCOHOL & DRUGS (40-6-391.A3) | 5
E01418132 | 40-6-391.A4 | DUI - MULTIPLE SUBSTANCES-MISD (40-6-391.A4) | 5
E01418132 | 40-6-391(A)5 | D.U.I. PERSON CONCENTRATION (40-6-391(A)5) | 5
E01418135 | 40-6-391.A1 | D.U.I./ALCOHOL (40-6-391.A1) | 5
E01418135 | 40-6-391.A2 | D.U.I./DRUGS (40-6-391.A2) | 5
E01418135 | 40-6-391.A3 | D.U.I./ALCOHOL & DRUGS (40-6-391.A3) | 5
E01418135 | 40-6-391.A4 | DUI - MULTIPLE SUBSTANCES-MISD (40-6-391.A4) | 5
E01418135 | 40-6-391(A)5 | D.U.I. PERSON CONCENTRATION (40-6-391(A)5) | 5
E01418137 | 40-6-391.A1 | D.U.I./ALCOHOL (40-6-391.A1) | 5
E01418137 | 40-6-391.A2 | D.U.I./DRUGS (40-6-391.A2) | 5
E01418137 | 40-6-391.A3 | D.U.I./ALCOHOL & DRUGS (40-6-391.A3) | 5
E01418137 | 40-6-391.A4 | DUI - MULTIPLE SUBSTANCES-MISD (40-6-391.A4) | 5
E01418137 | 40-6-391(A)5 | D.U.I. PERSON CONCENTRATION (40-6-391(A)5) | 5
E01900237 | 40-5-20 | NO DRIVERS LICENSE | 13
E01900237 | 40-6-10. | FAILURE TO MAINTAIN INSURANCE | 13
E01900237 | 40-6-120 | IMPROPER TURNS | 13
E01900237 | 40-6-181(G).1 | SPEEDING 31 MPH AND OVER | 13
E01900237 | 40-6-241 | IMPROPER USE OF RADIO AND MOBILE | 13
E01900237 | 40-6-270 | HIT & RUN/FAIL TO RENDER AID | 13
E01900237 | 40-6-390 | RECKLESS DRIVING | 13
E01900237 | 40-6-395 | ATTEMP TO ELUDE/IMPERS POLICE | 13
E01900237 | 40-6-46 | NO PASSING ZONE | 13
E01900237 | 40-6-48 | FAILURE TO MAINTAIN LANE | 13
E01900237 | 40-6-50 | DRIVING IN EMERGENCY LANE/GORE | 13
E01900237 | 40-6-72(B) | FAILURE TO STOP FOR STOP SIGN | 13
E01900237 | 40-6-73 | FAIL TO YIELD RIGHT OF WAY WHILE ENTER ROADWAY | 13
E01954203 | 106-81(7) | DC SEC 7-PHYSICAL OBSTRUCT ANOTHER | 15
E01954203 | 106-90 | FALSE REPRESENTATION TO POLICE | 15
E01954203 | 40-5-121 | DRIVE W/LICENSE SUSP/REVOKED | 15
E01954203 | 40-5-29(B) | REFUSE TO DISPLAY LICENSE | 15
E01954203 | 40-6-123(B) | FAILURE TO USE CORRECT SIGNAL | 15
E01954203 | 40-6-181(G).1 | SPEEDING 31 MPH AND OVER | 15
E01954203 | 40-6-390 | RECKLESS DRIVING | 15
E01954203 | 40-6-391.A1 | D.U.I./ALCOHOL (40-6-391.A1) | 15
E01954203 | 40-6-391.A2 | D.U.I./DRUGS (40-6-391.A2) | 15
E01954203 | 40-6-391(A)3 | DUI-INHALENTS (40-6-391(A)3) | 15
E01954203 | 40-6-391.A4 | DUI - MULTIPLE SUBSTANCES-MISD (40-6-391.A4) | 15
E01954203 | 40-6-391(A)5 | D.U.I. PERSON CONCENTRATION (40-6-391(A)5) | 15
E01954203 | 40-6-48 | FAILURE TO MAINTAIN LANE | 15
E01954203 | 40-6-49 | FOLLOWING TOO CLOSELY | 15
E01954203 | 40-8-76.1 | SAFETY BELT VIOLATION | 15

... these results feel like genuine representations of multiple violations per citation, especially in the case of the hit-and-run/car chase GUIDs represented towards the bottom of the sample.






#### Multiple Locations per GUID

```` sql
-- how many guid values have more than one location?
SELECT count(DISTINCT guid)
FROM (
  SELECT
    r.guid
    ,count(DISTINCT location) AS location_count
  FROM atlanta_endpoint_objects r
  GROUP BY 1
  HAVING count(DISTINCT location) > 1
  ORDER BY 2 DESC
) dups; -- > 827 / 407,118 * 100 = 0.2%
````

```` sql
-- what's going on with guid values that have more than one location?
SELECT
  uniqs.guid
  ,uniqs.location
  ,dups.location_count
FROM (
  SELECT guid, count(distinct location) as location_count
  FROM atlanta_endpoint_objects
  GROUP BY 1
  HAVING count(distinct location) > 1
  ORDER BY 1
) dups
JOIN (
  SELECT distinct guid, location FROM atlanta_endpoint_objects
) uniqs ON dups.guid = uniqs.guid
ORDER BY 3,1;
````

=> (sample)

guid | location | location_count
--- | --- | ---
000052 | 1500 DONALD LEE HOLLOWELL | 2
000052 | COLINS ST @ LOWER WALL ST | 2
000053 | 208 SKAPPER DR | 2
000053 | CSX RAILROAD PRIVATE PROPERTY @ LOWER WALL | 2
037716 | EDGEWOOD AV | 2
037716 | UNKNOWN | 2
039698 | JESSE HILL COCA COLA PL | 2
039698 | JESSE HILL/COCA  COLA   PL | 2
039810 | GILMER ST | 2
039810 | GILMER  ST | 2
09302014 | CHESHIRE BR/FAULKER RD | 2
09302014 | WEST END/WESTVIEW | 2
132875 | 216    PTREE   ST  NE | 2
132875 | 216    PTREE   ST   NE | 2
1643624 | 195 FAIRBURN RD | 2
1643624 | 2539 PIEDMONT RD | 2
1816031 | 895 SIMPSON RD NW | 2
1816031 | SOUTH ON MARIETT BLVD / BOLTON PL | 2
2083756 | SUSY GRIFFIN RD | 2
2083756 | SUSYGRIFFIN RD | 2
2128050 | 3201 ATLANTA INDUSTRIAL PKWY | 2
2128050 | 3201 ATL INDUSTRIAL | 2
2134366 | 80 JESSE  HILL JR DR | 2
2134366 | 80 JESSE HILL JR DR | 2
2183373 | 760 WEST PEACHTREE STREET | 2
2183373 | 857 MAYTEL ST | 2
2183374 | 1073 PIEDMONT AVE | 2
2183374 | 760 WEST PEACHTREE STREET | 2
2195717 | 3500 PRTREE | 2
2195717 | 3500 PTREE ST | 2
2280732 | 30030 HEADLORD DRIVE | 2
2280732 | 3030 HEADLAND DR | 2
2295786 | 502    LYNNHAVEN    DR | 2
2295786 | 502 LYNNHAVEN DR | 2


... a good portion look like typos and/or spelling variations and/or different levels of specificity, but the question still remains - "may a citation have multiple locations or only one?"

Either way this data is dirty and needs proper location validation or auto lat/long assignment via GPS.

#### Multiple Payables per GUID

```` sql
-- how many guid values have more than one payable?
SELECT count(DISTINCT guid)
FROM (
  SELECT
    r.guid
    ,count(DISTINCT payable) AS location_count
  FROM atlanta_endpoint_objects r
  GROUP BY 1
  HAVING count(DISTINCT payable) > 1
  ORDER BY 2 DESC
) dups; -- > 4,556 / 407,118 * 100 = 1.1%
````




<hr>


#### Multiple Violation Codes per Violation Description

Some violations most likely refer to the same thing, but are worded differently (e.g. `'FAILURE TO YIELD TO PEDESTRIAN AT CROSSWALK'` vs `'YTD TO PEDESTRIAN IN CROSSWALK'`). Are these data integrity issues or truly different violations?

Some violations have the same exact description but different codes...

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

... so which signify data integrity issues, and which (if any) signify different severity levels  for the same violation?

Violations need unique codes, and data capture processes need to perform proper violation code and description validations.

#### Multiple Payables per Violation

If `payable` does not describe `guid`, does it describe `violation`?

```` sql
SELECT
 violation
 ,description
 ,count(DISTINCT payable) AS payable_count
FROM atlanta_endpoint_objects
GROUP BY 1, 2
HAVING count(DISTINCT payable) > 1
ORDER BY 3 desc
````

=>

violation | description | payable_count
--- | --- | ---
40-6-184A | SPEED LESS THAN MINIMUM MOVING VIOLATION | 2
40-6-184C | IMPEDING TRAFFIC FLOW-LEFT LANE VIOLATION | 2
40-8-76 | FAIL/USE CHILD SEAT/SEAT BELT | 2
40-6-43 | IMPR PASSING ON THE RIGHT | 2
40-6-126 | CENTER LANE VIOLATION | 2
10-8 | DRINKING IN PUBLIC | 2
40-6-241 | IMPROPER USE OF RADIO AND MOBILE | 2
40-6-203(A)(1)(B) | PARKING ON SIDEWALK | 2
40-6-241.2(B) | TEXTING WHILE DRIVING PROHIBITED (OVER 18) | 2
40-6-203(A)(1)(C) | PARKING WITHIN INTERSECTION | 2
40-6-52(B) | TRUCKS USING MULTILANE HIGHWAY (3+ LANES) | 2
40-6-203(A)(1)(D) | PARKING ON CROSSWALK | 2
40-6-45(A)1 | PASSING ON HILL OR CURVE | 2
40-6-92 | PED CROSS NOT A CROSSWALK/JAY WALKING | 2
40-6-92(A) | YIELD WHILE CROSSING ROADWAY | 2
40-6-203(A)(1)(E) | PARKING TO CLOSE TO SAFETY ZONE | 2
40-6-92(C) | CROSSING ELSEWHERE THAN CROSS | 2
40-6-202 | S/S OR PARKING OUTSIDE BUS/RES-BLOCKING ST. | 2
40-6-203(A)(1)(G) | STOPPING ON BRIDGE/TUNNEL | 2
40-6-16 | GA MOVE OVER LAW | 2
40-6-203(A)(1)(I) | PARKING ON CONTROL ACCESS (INTERSTATE) HWY | 2
40-6-203(A)(1)(K) | PARKING PROHIBITED (SIGNS PROHIBITED) | 2
40-6-203(A)(2)(A) | BLOCKING PUBLIC/PRIVATE DRIVEWAY | 2
40-6-203(A)(2)(B) | PARKING WITHIN 15 FEET OF FIRE HYDRANT | 2
40-6-49 | FOLLOWING TOO CLOSELY | 2
40-6-203(A)(2)(C) | PARKING WITHIN 20 FEET OF CROSSWALK AT INTERSECTION | 2
40-6-144 | FAILURE TO YLD ENTERING STREET | 2
40-6-254 | FAILURE TO SECURE LOAD | 2
40-6-200 | IMPROPER PARKING | 2
40-6-50 | DRIVING IN EMERGENCY LANE/GORE | 2
40-6-200(A) | VEH. STOPPED/PRK ON 2-WAY RDWY | 2
40-6-74 | FAIL TO YLD RIGHT OF WAY FOR EMERGENCY VEH | 2
40-6-74.A | FAIL TO YIELD FOR EMERGENCY VEHICLES | 2
40-8-22 | IMPROPERLY WORKING HEADLIGHTS | 2
40-6-74(A) | FAIL TO YLD FOR EMGCY VEHCLS | 2
40-8-22(D) | MATERIAL COVERING HEADLIGHTS ARE PROHIBITED | 2
40-6-226(A) | HANDICAP PARKING- PERMIT NOT DISPLAYED | 2
40-6-74(B) | UNSAFE OPERATION OF EMERGENCY VEHICLE | 2

... nope.

#### Multiple Payables per Hearing

If `payable` does not describe `guid` or `violation`, does it describe the hearing?

```` sql
SELECT
 room ,DATE ,TIME
 ,defendant
 ,count(DISTINCT payable) AS payable_count
FROM atlanta_endpoint_objects
GROUP BY 1, 2,3 ,4
HAVING count(DISTINCT payable) > 1
ORDER BY 5,4 desc;
````

... nope.

#### What does payable describe?

Even though the data shows multiple `payable` values per `guid`, [this courtbot code](https://github.com/codeforamerica/courtbot/blob/4e861d4066ab1d56797f7c1e9b9d20900cbd4ee7/web.js#L120)
 suggests there should only be one payable per citation, and that a hearing is payable if all component citations are payable.


#### Multiple Citations per Case

Additional Context from http://ditweb.atlantaga.gov/mcw/:

Case Number	| Citation	| Defendant	 | Last Known City	| Violation Code	| Violation Code Description
---	| ---	| ---	 | ---	| ---	| ---
15TR138716	| 5060184	| ABERNATHY, TEREANCE	| JACKSONVILLE, AL	| 40-5-121	| DRIVE W/LICENSE SUSP/REVOKED
15TR138716	| 5060185	| ABERNATHY, TEREANCE	| JACKSONVILLE, AL	| 40-6-250	| OPERATING A VEHICLE WHILE WEARING HEADPHONES
15TR138716	| 5060186	| ABERNATHY, TEREANCE	| JACKSONVILLE, AL	| 40-8-74	  | UNSAFE TIRES


The case number is nowhere to be found in the data but the citation number matches a GUID belonging to the defendant.

This evidence, along with [this line of courtbot code](https://github.com/codeforamerica/courtbot/blob/master/utils/loaddata.js#L75),
  suggest there are multiple citations per court case, and that GUIDs are citation identifiers.
