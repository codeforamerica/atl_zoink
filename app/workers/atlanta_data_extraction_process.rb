class AtlantaDataExtractionProcess
  def self.perform
    endpoints = Rails.env == "test" ? AtlantaEndpoint.extraction_testworthy : AtlantaEndpoint.extraction_eligible
    endpoints = endpoints.order(:upload_date => :desc)
    puts "EXTRACTING DATA FROM #{endpoints.count} ENDPOINTS ..."

    endpoints.each do |endpoint|
      puts endpoint.url
      requested_at = Time.zone.now
      response = HTTParty.get(endpoint.url)
      response_received_at = Time.zone.now

      if response.code == 200 && response.body.encoding.to_s == "UTF-8" #todo: fix encoding issue
        inserts = []
        rows = CSV.parse(response.body, {
          :col_sep => "|", # should parse pipe-delimited data
          :quote_char => "\x00", # should parse unexpected values like "SMITH, DANT"E",
          :encoding => response.body.encoding.to_s # should be able to read "ASCII-8BIT" characters like "\xA0"
        })

        puts "FOUND #{rows.count} ROWS ..."

        rows.each do |row| # ["04-AUG-14", "PRICE, ROBERT ALAN", "REGINA DR", "6C", "03:00:00 PM", "4707082", "40-6-48", "FAILURE TO MAINTAIN LANE", "1"]
          inserts << "(
            #{endpoint.id},
            '#{cleanse(row[0])}',
            '#{cleanse(row[1])}',
            '#{cleanse(row[2])}',
            '#{cleanse(row[3])}',
            '#{cleanse(row[4])}',
            '#{cleanse(row[5])}',
            '#{cleanse(row[6])}',
            '#{cleanse(row[7])}',
            '#{cleanse(row[8])}'
          )"
        end

        sql_string = "INSERT INTO atlanta_endpoint_objects (endpoint_id, date, defendant, location, room, time, guid, violation, description, payable) VALUES #{inserts.join(', ')}"

        begin
          ActiveRecord::Base.connection.execute(sql_string)
        rescue => e
          puts "#{e.class} -- #{e.message}"
          binding.pry unless Rails.env == "production"
        end

        extracted_at = Time.zone.now
      end

      endpoint.update!({
        :requested_at => requested_at,
        :response_received_at => response_received_at,
        :response_code => response.code,
        :string_encoding => response.body.encoding.to_s,
        :row_count => rows.try(:count),
        :extracted_at => extracted_at,
      })
    end

    puts "EXTRACTED XXX ROWS FROM #{endpoints.count} ENDPOINTS ..."
  end

  def self.cleanse(str)
    begin
      str1 = str.try(:gsub, "'", "???") #.try(:gsub, "\xA0","???")
    rescue => e
      puts "#{e.class} -- #{e.message}"
      binding.pry unless Rails.env == "production"
    end
  end
end
