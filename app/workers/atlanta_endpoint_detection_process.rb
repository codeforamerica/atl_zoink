class AtlantaEndpointDetectionProcess
  def self.perform
    puts "DETECTING ENDPOINTS ..."
    before_count = AtlantaEndpoint.count
    AtlantaEndpoint.possible_upload_dates.each do |d|
      AtlantaEndpoint.where(:upload_date => d).first_or_create!
    end
    after_count = AtlantaEndpoint.count
    puts "DETECTED #{after_count - before_count} NEW ENDPOINTS (#{after_count} TOTAL)"
  end
end
