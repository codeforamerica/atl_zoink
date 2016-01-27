namespace :atlanta do
  desc "Extract, transform, and load data from the Atlanta Courtbot API."
  task :etl => :environment do

    #
    # Persist metadata of potential urls.
    #

    potential_upload_dates = ("2014-01-01".to_date .. Date.today)
    potential_upload_dates.each do |d|
      DataUrl.where(:upload_date => d).first_or_create!
    end

    #
    # Extract, transform, and load .csv data.
    #

    data_urls = DataUrl.found.unextracted
    data_urls.each do |du|
      du.update!({:requested_at => Time.zone.now})
      response = HTTParty.get(du.url)
      du.update!({:response_code => response.code})
      puts du.inspect # unless Rails.env == "production"

      next unless du.response_code == 200

      du.update!({:string_encoding => response.body.encoding.to_s})
      next if du.string_encoding != "UTF-8" #todo: transcode instead of skipping these 11 files

      row_counter = 0
      CSV.parse(response.body, du.csv_parse_options).each do |row|
        violation = Violation.where({
          :guid => row[6], # "123456789",
          :description => row[7], # "A FAKE VIOLATION"
        }).first_or_create!

        citation = Citation.where({
          :guid => row[5], # "123456789",
          :violation_id => violation.id,
          :location => row[2], # "123 FAKE STREET",
          :payable => row[8], # 1
        }).first_or_create!

        Appointment.where({
          :citation_id => citation.id,
          :defendant_full_name => row[1], # "Fake Person",
          :room => row[3], # "3B",
          :date => row[0], # "20-JAN-15",
          :time => row[4], # "03:00:00 PM"
        }).first_or_create!

        row_counter+=1
      end

      du.update!({:extracted => true, :extracted_at => Time.zone.now, :row_count => row_counter})
    end
  end
end
