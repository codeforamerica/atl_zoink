class AtlantaEndpoint < ActiveRecord::Base
  has_many :rows, :class_name => AtlantaEndpointObject, :inverse_of => :endpoint, :foreign_key => :endpoint_id

  EARLIEST_POSSIBLE_UPLOAD_DATE = "2014-01-01".to_date

  def self.latest_possible_upload_date
    Date.today
  end

  def self.possible_upload_dates
    (EARLIEST_POSSIBLE_UPLOAD_DATE .. latest_possible_upload_date)
  end

  def self.extraction_eligible
    where("extracted_at IS NULL")
    .where("response_code IS NULL OR response_code <> 404")
  end

  # A set of endpoints with varying characteristics used for testing purposes.
  # Expects there to be only one valid data endpoint, the one specified by utf8_encoding_date.
  def self.extraction_testworthy
    four_oh_four_date = ["2014-01-01","2014-02-01","2014-03-01","2014-04-01","2014-05-01","2014-06-01","2014-07-01","2014-08-01","2014-09-01","2014-10-01","2014-11-01"].sample.to_date
    ascii_encoding_date = ["2015-03-12","2015-04-12","2015-05-12","2015-06-12","2015-07-12","2015-08-12","2015-09-12","2015-10-12","2015-11-12","2015-12-12","2016-01-01"].sample.to_date
    utf8_encoding_date = ["2014-01-08","2014-02-08", "2014-03-08", "2014-04-08","2014-05-08","2014-06-08","2015-05-08","2015-08-08","2015-12-08"].sample.to_date
    no_rows_date = ["2015-01-08","2015-02-08","2015-07-06","2015-09-06","2015-11-07","2015-12-07"].sample.to_date
    where(:upload_date => [four_oh_four_date, ascii_encoding_date, utf8_encoding_date, no_rows_date])
  end

  # @param [Integer] int The HTTP response code (like 200 or 404).
  def self.responded_with_code(int)
    where(:response_code => int)
  end

  def self.extracted
    where("extracted_at IS NOT NULL")
  end

  def self.malencoded
    where("string_encoding <> 'UTF-8'")
  end

  # @example "20012014"
  def url_date
    upload_date.strftime("%d%m%Y")
  end

  def url
    "http://courtview.atlantaga.gov/courtcalendars/court_online_calendar/codeamerica.#{url_date}.csv"
  end
end
