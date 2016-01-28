class AtlantaEndpointsController < ApplicationController
  def index
    @endpoints = AtlantaEndpoint.all.order(:upload_date => :desc)
    @message = "Long live the bot."
  end
end
