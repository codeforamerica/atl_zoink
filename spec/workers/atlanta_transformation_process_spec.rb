require 'rails_helper'

RSpec.describe AtlantaTransformationProcess do
  let(:citation_guids){ AtlantaCitation.pluck(:guid).uniq.sort }
  let(:violation_codes){ AtlantaViolation.pluck(:code).uniq.sort }

  let(:appointment_date){"20-JAN-15"}
  let(:appointment_time){"03:00:00 PM"}
  let(:appointment_at){"2015-01-20T15:00:00+00:00"}

  before do
    #AtlantaEndpointDetectionProcess.perform
    #AtlantaDataExtractionProcess.perform
    #AtlantaDeduplicationProcess.perform
    AtlantaTransformationProcess.perform
  end

  describe ".perform" do
    it "should transform deduplicated data into the desired schema (citations)." do
      sql_string = "SELECT DISTINCT guid FROM atlanta_distinct_objects ORDER BY guid"
      result = ActiveRecord::Base.connection.execute(sql_string)
      expected_citation_guids = result.to_a.map{|r| r["guid"]}
      expect(citation_guids).to eql(expected_citation_guids)
    end

    it "should transform deduplicated data into the desired schema (violations)." do
      sql_string = "SELECT DISTINCT violation FROM atlanta_distinct_objects ORDER BY violation"
      result = ActiveRecord::Base.connection.execute(sql_string)
      expected_violation_codes = result.to_a.map{|r| r["violation"]}
      expect(violation_codes).to eql(expected_violation_codes)
    end

    it "should transform deduplicated data into the desired schema (hearings test)." do
      pending
    end

    it "should transform separate date and time fields into a single datetime.", :skip_before => true do
      expect(DateTime.parse("#{appointment_date} #{appointment_time}").to_s).to eql(appointment_datetime)
    end

    it "should transform rows in chronological order to acheive the desired attribute update behavior (more current values overwrite old values)." do
      pending
    end
  end
end
