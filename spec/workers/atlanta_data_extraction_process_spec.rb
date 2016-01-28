require 'rails_helper'

RSpec.describe AtlantaDataExtractionProcess do
  before do
    if RSpec.configuration.use_transactional_fixtures == false
      AtlantaEndpoint.destroy_all
      AtlantaEndpointObject.destroy_all
    end
    AtlantaEndpointDetectionProcess.perform
    AtlantaDataExtractionProcess.perform
  end

  describe ".perform" do
    it "should ascertain and persist the http response code of each endpoint." do
      expect(AtlantaEndpoint.pluck(:response_code).uniq.compact.sort).to eql([200,404])
    end

    it "should ascertain and persist the .csv string endoding for each endpoint." do
      expect(AtlantaEndpoint.pluck(:string_encoding).uniq.compact.sort).to eql(["ASCII-8BIT", "UTF-8"])
    end

    it "should ascertain and persist the row count for each applicable endpoint" do
      expect( AtlantaEndpoint.responded_with_code(200).extracted.pluck(:row_count) ).to_not include(nil)
    end

    it "should persist all available .csv rows in the database." do
      expected_row_count = AtlantaEndpoint.responded_with_code(200).extracted.sum(:row_count)
      expect(AtlantaEndpointObject.count).to eql(expected_row_count)
      #binding.pry
      #expect(AtlantaEndpointObject.count).to be > 5000 # this is kind of lame...
    end

    ###it "should only attempt to extract data from eligible endpoints." do
    ###  pending
    ###end
  end
end
