require 'rails_helper'

RSpec.describe AtlantaDeduplicationProcess do
  describe ".perform" do
    let(:expected_attributes){
      ["date", "defendant", "description", "endpoint_ids", "guid", "location", "min_object_id", "object_count", "object_ids", "payable", "room", "time", "violation"]
    }

    before do
      AtlantaDeduplicationProcess.perform
    end

    it "should create a new table which does not contain any duplicate value combinations." do
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
          ,count(*) AS row_count
        FROM atlanta_distinct_objects dr
        GROUP BY 1,2,3,4,5,6,7,8,9
        HAVING count(*) > 1
      SQL
      result = ActiveRecord::Base.connection.execute(sql_string)
      expect(result.ntuples).to eql(0)
    end

    it "should create a new table which contains the expected attributes." do
      sql_string = "SELECT * FROM atlanta_distinct_objects LIMIT 10;"
      result = ActiveRecord::Base.connection.execute(sql_string)
      expect(result.fields.sort).to eql(expected_attributes)
    end
  end
end
