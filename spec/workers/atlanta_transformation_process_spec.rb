require 'rails_helper'

RSpec.describe AtlantaTransformationProcess do
  let(:citation_guids){ Citation.pluck(:guid).uniq.sort }
  let(:violation_codes){ Violation.pluck(:code).uniq.sort }

  before do
    AtlantaDeduplicationProcess.perform
    AtlantaTransformationProcess.perform
  end

  describe ".perform" do
    it "should transform deduplicated data into the desired schema (citations test)." do
      sql_string = "SELECT DISTINCT guid FROM atlanta_distinct_objects ORDER BY guid"
      result = ActiveRecord::Base.connection.execute(sql_string)
      expected_citation_guids = result.to_a
      binding.pry
      expect(citation_guids).to eql(expected_citation_guids)
    end

    it "should transform deduplicated data into the desired schema (violations test)." do
      sql_string = "SELECT DISTINCT violation FROM atlanta_distinct_objects ORDER BY violation"
      result = ActiveRecord::Base.connection.execute(sql_string)
      expected_violation_codes = result.to_a
      binding.pry
      expect(violation_codes).to eql(expected_violation_codes)
    end

    it "should transform deduplicated data into the desired schema (hearings test)." do
      pending
    end
  end
end
