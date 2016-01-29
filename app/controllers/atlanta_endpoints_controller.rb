class AtlantaEndpointsController < ApplicationController
  def index
    @endpoints = AtlantaEndpoint.all.order(:upload_date => :desc)
    @row_count = AtlantaEndpoint.sum(:row_count)
    @extracted_endpoint_count = AtlantaEndpoint.extracted.count
  end
end
