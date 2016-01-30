require 'rails_helper'

RSpec.describe AtlantaDataExtractionProcess do
  before do
    if RSpec.configuration.use_transactional_fixtures == false
      AtlantaEndpoint.destroy_all
      AtlantaEndpointObject.destroy_all
    end
    AtlantaEndpointDetectionProcess.perform
  end

  describe ".perform" do
    it "should ascertain and persist the http response code of each endpoint." do
      AtlantaDataExtractionProcess.perform
      expect(AtlantaEndpoint.pluck(:response_code).uniq.compact.sort).to eql([200,404])
    end

    it "should ascertain and persist the .csv string endoding for each endpoint." do
      AtlantaDataExtractionProcess.perform
      expect(AtlantaEndpoint.pluck(:string_encoding).uniq.compact.sort).to eql(["ASCII-8BIT", "UTF-8"])
    end

    it "should ascertain and persist the row count for each applicable endpoint" do
      AtlantaDataExtractionProcess.perform
      expect( AtlantaEndpoint.responded_with_code(200).extracted.pluck(:row_count) ).to_not include(nil)
    end

    it "should persist all available .csv rows in the database." do
      AtlantaDataExtractionProcess.perform
      expected_row_count = AtlantaEndpoint.responded_with_code(200).extracted.sum(:row_count)
      expect(AtlantaEndpointObject.count).to eql(expected_row_count)
      #binding.pry
      #expect(AtlantaEndpointObject.count).to be > 5000 # this is kind of lame...
    end

    ###it "should only attempt to extract data from eligible endpoints." do
    ###  pending
    ###end

    context "when the csv string contains zero rows" do
      subject(:performance){AtlantaDataExtractionProcess.perform}
      it "should not attempt to insert rows into the database but should consider the extraction as having happened." do
        # specifically should avoid ActiveRecord::StatementInvalid: PG::SyntaxError: ERROR:  syntax error at end of input
        expect{performance}.to_not raise_error
        expect{performance}.to_not raise_error(/PG::SyntaxError/)
      end
    end

    context "when the csv string encoding is ASCII-8BIT" do
      subject(:performance){AtlantaDataExtractionProcess.perform}
      it "should convert string encoding to UTF-8." do
        # should avoid ActiveRecord::StatementInvalid: PG::CharacterNotInRepertoire: ERROR:  invalid byte sequence for encoding 'UTF8': 0xa0
        expect{performance}.to_not raise_error
        expect{performance}.to_not raise_error(/PG::CharacterNotInRepertoire/)
      end
    end
  end
end
