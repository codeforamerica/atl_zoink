class DataUrlsController < ApplicationController
  def index
    @data_urls = DataUrl.all.order(:upload_date => :desc)
    @message = "Long live the bot."
  end
end
