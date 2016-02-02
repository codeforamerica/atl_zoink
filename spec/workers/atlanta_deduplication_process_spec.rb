require 'rails_helper'

RSpec.describe AtlantaDeduplicationProcess do
  describe ".perform" do
    it "should not contain any duplicate value combinations." do
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
      expect(result.count).to eql(0)
    end
  end
end
