# Queries

## Summaries

On production ...

### Defendants

### Locations

### Violations

### Payables

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


### Appointments

```` sql
-- how many appointments per room?
SELECT
  room
  ,count(DISTINCT id) AS row_count
FROM atlanta_endpoint_objects
GROUP BY 1
ORDER BY 1;
````

```` sql
-- how many appointments per time?
SELECT
  TO_TIMESTAMP(time, 'HH24:MI:SS AM')::TIME AS appointment_time
  ,count(DISTINCT id) AS row_count
FROM atlanta_endpoint_objects
GROUP BY 1
ORDER BY 1;
````
