class AtlantaDeduplicationProcess
  def self.perform
    sql_string = <<-SQL

      DROP TABLE if EXISTS atlanta_distinct_objects; -- destructive!
      CREATE TABLE atlanta_distinct_objects AS (

        SELECT
          r.guid
          ,r.location
          ,r.payable
          ,r.defendant
          ,r.date
          ,r.time
          ,r.room
          ,r.violation
          ,r.description
          ,count(DISTINCT r.id) AS object_count
          ,min(r.id) as min_object_id
          ,string_agg(r.id::VARCHAR, ', ' ORDER BY r.id) AS object_ids
          ,string_agg(r.endpoint_id::VARCHAR, ', ' ORDER BY r.endpoint_id) AS endpoint_ids
        FROM atlanta_endpoint_objects r
        GROUP BY 1,2,3,4,5,6,7,8,9
        ORDER BY r.guid, r.date

      );
      ALTER TABLE atlanta_distinct_objects ADD PRIMARY KEY (min_object_id);
      CREATE INDEX guid_index ON atlanta_distinct_objects (guid);
      CREATE INDEX violation_index ON atlanta_distinct_objects (violation);

    SQL

    ActiveRecord::Base.connection.execute(sql_string)
  end
end
