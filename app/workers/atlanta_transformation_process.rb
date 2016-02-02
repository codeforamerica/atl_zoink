class AtlantaTransformationProcess
  VIOLATION_CODE_EDITS = [
    {
      :old_val => "LOITERING AROUND RAIILROAD TRKS/SHPS",
      :new_val => "LOITERING AROUND RAILROAD TRKS/SHPS"
    },
    {
      :old_val => "SKATING ON OTHER RINKS OERMIT",
      :new_val => "SKATING ON OTHER RINKS PERMIT"
    },
    {
      :old_val => "LOTTERING REQUIRED ON VEHICLE",
      :new_val => "LETTERING REQUIRED ON VEHICLE"
    }
  ] # small enough scope to implement this transformation lookup table

  def self.perform
    sql_string = <<-SQL
      SELECT
        dr.guid
        ,dr.location
        ,dr.payable
        ,dr.defendant
        ,dr.date
        ,dr.time
        ,dr.room
        ,dr.violation
        ,dr.description
        ,dr.object_count
        ,dr.min_object_id
        ,dr.object_ids
        ,dr.endpoint_ids
      FROM atlanta_distinct_objects dr
    SQL

    result = ActiveRecord::Base.connection.execute(sql_string)
    result.each do |row|
=begin
      row = {
         "guid"=>"000143",
         "location"=>"720 BOLTON RD",
         "payable"=>"f",
         "defendant"=>"FERRELL, JACQUESSIA R",
         "date"=>"10-DEC-15",
         "time"=>"01:00:00 PM",
         "room"=>"3B",
         "violation"=>"18-124(B)(1)",
         "description"=>"DOGS RUNNING AT LARGE",
         "object_count"=>"1",
         "min_object_id"=>"980486",
         "object_ids"=>"980486",
         "endpoint_ids"=>"36836"
       }
=end

      violation_description = VIOLATION_CODE_EDITS.find{|h| h[:old_val] == row["description"]}.try(:[], "new_val".to_sym) || row["description"]
      violation = Violation.where({:code => row["violation"]})
      violation.update_attributes({
        :description => violation_description
      })

      citation = Citation.where({:guid => row["guid"]}).first_or_initialize
      citation.update_attributes!({
        :defendant => row["defendant"]
        :location => row["location"],
        :payable => row["payable"]
      })

      citation.violations << violation

      citation_hearing = CitationHearing.where({
        :citation_guid => citation.guid,
        :appointment_at => DateTime.parse("#{row["date"]} #{row["time"]}")
      })
      citation_hearing.update_attributes!({:appointment_room => row["room"]})
    end
  end
end
