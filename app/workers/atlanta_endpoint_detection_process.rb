class AtlantaEndpointDetectionProcess
  def self.perform
    AtlantaEndpoint.possible_upload_dates.each do |d|
      AtlantaEndpoint.where(:upload_date => d).first_or_create!
    end
  end
end
