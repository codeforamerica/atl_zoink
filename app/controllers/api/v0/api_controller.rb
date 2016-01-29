class Api::V0::ApiController < ApplicationController
  def top_violations
    @violations = [1,2,3,4]

    respond_to do |format|
      format.json { render json: @violations }
    end
  end
end
