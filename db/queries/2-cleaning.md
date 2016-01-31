# Queries

## Cleaning and Quarantining

### Multiple Violation Codes per Violation Description

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
