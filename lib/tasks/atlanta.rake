namespace :atlanta do

  desc "Detect all possible Atlanta Courtbot API endpoints."
  task :detect => :environment do
    AtlantaEndpointDetectionProcess.perform
  end

  desc "Extract .csv data from eligible Atlanta Courtbot API endpoints."
  task :extract => :detect do
    AtlantaDataExtractionProcess.perform
  end

  desc "Deduplicate Atlanta data into distinct rows."
  task :deduplicate => :extract do
    AtlantaDeduplicationProcess.perform
  end

  desc "Transform and load deduplicated Atlanta data."
  task :transform_and_load => :deduplicate do
    AtlantaTransformationProcess.perform
  end
end
