class Api::V0::ApiController < ApplicationController
  def top_violations
    @violations = [
      {"violation_name": "FAILURE TO OBEY", "citation_count": 635},
      {"violation_name": "URINATING IN PUBLIC", "citation_count": 203},
      {"violation_name": "SAFETY BELT VIOLATION", "citation_count": 107},
      {"violation_name": "FOLLOWING TOO CLOSELY", "citation_count": 31},
      {"violation_name": "SPEEDING 19 to 23 MPH OVER", "citation_count": 20}
    ]

    respond_to do |format|
      format.json { render json: @violations }
    end
  end
end
