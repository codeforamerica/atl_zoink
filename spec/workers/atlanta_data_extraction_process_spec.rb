require 'rails_helper'

RSpec.describe AtlantaDataExtractionProcess do
  before do
    AtlantaEndpointDetectionProcess.perform
    AtlantaDataExtractionProcess.perform
  end

  describe ".perform" do
    it "should ascertain and persist the http response code of each endpoint." do
      expect(AtlantaEndpoint.pluck(:response_code).uniq.compact.sort).to eql([200,404])
    end

    ###it "should ascertain and persist the .csv string endoding for each endpoint." do
    ###  expect(AtlantaEndpoint.pluck(:string_encoding).uniq).to include(["UTF-8","ASCII-8BIT"])
    ###end

    ###it "should persist all available .csv rows in the database." do
    ###  pending
    ###  #expect(two_oh_two.extracted_rows.count).to be_greater_than(50)
    ###end

    ###it "should only attempt to extract data from eligible endpoints." do
    ###  pending
    ###end
  end
end
