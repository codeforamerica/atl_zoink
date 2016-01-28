require 'rails_helper'

RSpec.describe AtlantaEndpointDetectionProcess, type: :model do
  describe ".perform" do
    it "should persist an atlanta_endpoint object for each possible upload date" do
      AtlantaEndpointDetectionProcess.perform
      endpoint_dates = AtlantaEndpoint.pluck(:upload_date)
      expect(endpoint_dates).to include(AtlantaEndpoint::EARLIEST_POSSIBLE_UPLOAD_DATE)
      expect(endpoint_dates).to include(AtlantaEndpoint.latest_possible_upload_date)
    end
  end
end
