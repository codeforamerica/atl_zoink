class DataUrl < ActiveRecord::Base
  def self.found
    where("response_code IS NULL OR response_code <> 404")
  end

  def self.unextracted
    where("extracted IS NULL OR extracted <> true")
  end

  def url_date
    upload_date.strftime("%d%m%Y") # "20012014"
  end

  def url
    "http://courtview.atlantaga.gov/courtcalendars/court_online_calendar/codeamerica.#{url_date}.csv"
  end

  def csv_parse_options
    {
      :col_sep => "|", # should parse pipe-delimited data
      :quote_char => "\x00", # should parse unexpected values like "SMITH, DANT"E",
      :encoding => string_encoding # should be able to read "ASCII-8BIT" characters like "\xA0"
    }
  end
end
