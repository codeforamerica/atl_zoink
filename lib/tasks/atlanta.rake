namespace :atlanta do

  desc "Detect all possible Atlanta Courtbot API endpoints."
  task :detect => :environment do
    before_count = AtlantaEndpoint.count
    AtlantaEndpointDetectionProcess.perform
    after_count = AtlantaEndpoint.count
    puts "DETECTED #{after_count - before_count} NEW ENDPOINTS (#{after_count} TOTAL)"
  end

  ###desc "Extract raw csv data from the Atlanta Courtbot API."
  ###task :extract => :detect do
  ###  AtlantaExtractionProcess.perform
  ###end

  ###desc "Extract, transform, and load data from the Atlanta Courtbot API."
  ###task :etl => :environment do
  ###  AtlantaEtlProcess.perform
  ###end
end
