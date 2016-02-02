# Queries

## Enhancements

### Categorizing Violations

> NOTE: violation categorization is in progress ... https://github.com/kuanb/atl_zoink/issues/9

```` sql
/*
SELECT description FROM atlanta_distinct_objects WHERE description LIKE '%ZONING%' ORDER BY description;
*/

SELECT *
FROM (
  SELECT

    dr.description AS violation_description
    ,CASE
      WHEN dr.description = 'ZONING VIOLATION'
        THEN 'HOUSING AND BUSINESS'
      WHEN dr.description LIKE '%YIELD%'
        OR dr.description = 'YTD TO PEDESTRIAN IN CROSSWALK'
        OR dr.description = 'PARKING OF COMMERCIAL TRLR PROHIBITED IN CERTAIN ZONING DISTRICTS'
        THEN 'DRIVING'
      WHEN dr.description = 'PEDESTRIAN DARTING OUT IN TRAFFIC'
        OR dr.description = 'PEDESTRIAN OBSTRUCTING TRAFFIC'
        OR dr.description = 'FAILURE TO YIELD TO PEDESTRIAN AT CROSSWALK'
        THEN 'PEDESTRIANISM'


      ELSE 'TODO'
    END violation_category
  FROM atlanta_distinct_objects dr
  ORDER BY violation_category, violation_description DESC
) categorizations
WHERE violation_category = 'TODO'
````
