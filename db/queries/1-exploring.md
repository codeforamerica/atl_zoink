# Queries

## Performance

```` sql
SELECT count(DISTINCT id) FROM atlanta_endpoint_objects; -- > 6,734,949 rows; 6,520 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; -- > 390,831 rows; 231,604 ms
CREATE INDEX guid_index ON atlanta_endpoint_objects (guid); -- > 230,836 ms
SELECT count(DISTINCT guid) FROM atlanta_endpoint_objects; -- > 390,831 rows; 243,083 ms
````

... the full table of extracted objects is large and slow to query, and indexing is not a sufficient solution.

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

## Structure


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
ORDER BY 1; -- > 51,008 ms
````

```` sql
-- how many appointments per time?
SELECT
  TO_TIMESTAMP(time, 'HH24:MI:SS AM')::TIME AS appointment_time
  ,count(DISTINCT id) AS row_count
FROM atlanta_endpoint_objects
GROUP BY 1
ORDER BY 1; -- > 27,645 ms
````
