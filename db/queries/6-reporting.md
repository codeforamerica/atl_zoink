# Queries

> NOTE: these queries were written against a preliminary schema and are likely to change once a new schema is adopted.

## Reporting and Visualizations

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
