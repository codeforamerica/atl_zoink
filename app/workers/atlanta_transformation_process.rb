class AtlantaTransformationProcess
  VIOLATION_DESCRIPTION_CONVERSIONS = [
    {:old_val => "LOITERING AROUND RAIILROAD TRKS/SHPS", :new_val => "LOITERING AROUND RAILROAD TRKS/SHPS"},
    {:old_val => "SKATING ON OTHER RINKS OERMIT",:new_val => "SKATING ON OTHER RINKS PERMIT"},
    {:old_val => "LOTTERING REQUIRED ON VEHICLE",:new_val => "LETTERING REQUIRED ON VEHICLE"}
  ] # small enough scope to implement this transformation lookup table

  # @param [String] violation_description
  def self.clean_description(violation_description)
    VIOLATION_DESCRIPTION_CONVERSIONS.find{|h|
      h[:old_val] == violation_description
    }.try(:[], "new_val".to_sym) || violation_description
  end

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
      ORDER BY min_object_id -- should process earlier entries first so updates will be chronological
    SQL

    result = ActiveRecord::Base.connection.execute(sql_string)
    puts "TRANSFORMING AND LOADING #{result.count} RECORDS"
    progressbar = ProgressBar.create(:total => result.count) unless Rails.env.production?
    result.each do |row| #=> {"guid"=>"000143","location"=>"720 BOLTON RD","payable"=>"f","defendant"=>"FERRELL, JACQUESSIA R","date"=>"10-DEC-15","time"=>"01:00:00 PM","room"=>"3B","violation"=>"18-124(B)(1)","description"=>"DOGS RUNNING AT LARGE","object_count"=>"1","min_object_id"=>"980486","object_ids"=>"980486","endpoint_ids"=>"36836"}

      violation = AtlantaViolation.where({:code => row["violation"]}).first_or_initialize
      violation.update_attributes({
        :description => clean_description(row["description"])
      })

      citation = AtlantaCitation.where({:guid => row["guid"]}).first_or_initialize
      citation.update_attributes!({
        :defendant_full_name => row["defendant"],
        :location => row["location"],
        :payable => row["payable"]
      })

      citation_violation = AtlantaCitationViolation.where({
        :citation_guid => citation.guid,
        :violation_code => violation.code
      }).first_or_create!

      citation_hearing = AtlantaCitationHearing.where({
        :citation_guid => citation.guid,
        :appointment_at => DateTime.parse("#{row["date"]} #{row["time"]}")
      }).first_or_initialize
      citation_hearing.update_attributes!({:room => row["room"]})

      progressbar.increment unless Rails.env.production?
    end
  end
end
