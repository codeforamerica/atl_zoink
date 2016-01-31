# Queries

## Data Transformation


```` sql
SELECT
  r.id AS row_id
  ,r.endpoint_id
  ,r.guid
  ,r.defendant AS defendant_name

  ,r.violation AS violation_guid
  ,r.description AS violation_desc

  ,r.location AS citation_location
  ,r.payable AS citation_payable

  ,to_date(r.date, 'DD-MON-YY') + TO_TIMESTAMP(r.time, 'HH24:MI:SS')::TIME AS appointment_at
  ,r.room AS appointment_room
FROM atlanta_endpoint_objects r;
