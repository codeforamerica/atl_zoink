# Queries

## Enhancements

### Categorizing Violations

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
