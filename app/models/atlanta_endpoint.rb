class AtlantaEndpoint < ActiveRecord::Base
  EARLIEST_POSSIBLE_UPLOAD_DATE = "2014-01-01".to_date

  def self.latest_possible_upload_date
    Date.today
  end

  def self.possible_upload_dates
    (EARLIEST_POSSIBLE_UPLOAD_DATE .. latest_possible_upload_date)
  end
end
