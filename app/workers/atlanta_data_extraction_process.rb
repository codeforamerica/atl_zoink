class AtlantaDataExtractionProcess
  def self.perform
    endpoints = Rails.env == "production" ? AtlantaEndpoint.extraction_eligible : AtlantaEndpoint.extraction_testworthy
    puts "EXTRACTING DATA FROM #{endpoints.count} ENDPOINTS ..."

    endpoints.each do |endpoint|
      puts endpoint.inspect
      requested_at = Time.zone.now
      response = HTTParty.get(endpoint.url)
      response_received_at = Time.zone.now

      if response.code == 200
        puts "200!!"

        row_counter = nil
        extracted_at = nil
      #else
      #  row_counter = nil
      #  extracted_at = nil
      end

      endpoint.update!({
        :requested_at => requested_at,
        :response_received_at => response_received_at,
        :response_code => response.code,
        :string_encoding => response.body.encoding.to_s,
        :row_count => row_counter,
        :extracted_at => extracted_at,
      })
    end

    puts "EXTRACTED XXX ROWS FROM #{endpoints.count} ENDPOINTS ..."
  end

  # @param [String] encoding An encoding like "UTF-8" or "ASCII-8BIT"
  def csv_parse_options(encoding)
    {
      :col_sep => "|", # should parse pipe-delimited data
      :quote_char => "\x00", # should parse unexpected values like "SMITH, DANT"E",
      :encoding => encoding # should be able to read "ASCII-8BIT" characters like "\xA0"
    }
  end
end
