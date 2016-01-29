class Api::V0::ApiController < ApplicationController

  # Returns the top most-cited violations.
  # @example [
  #   {"violation_name": "FAILURE TO OBEY", "citation_count": 635},
  #   {"violation_name": "URINATING IN PUBLIC", "citation_count": 203},
  #   {"violation_name": "SAFETY BELT VIOLATION", "citation_count": 107},
  #   {"violation_name": "FOLLOWING TOO CLOSELY", "citation_count": 31},
  #   {"violation_name": "SPEEDING 19 to 23 MPH OVER", "citation_count": 20}
  # ]
  def top_violations
    query_string =<<-SQL
      SELECT
        v.id AS violation_id
        ,concat('ATL ', v.guid) AS violation_guid
        ,v.description AS violation_name
        ,'TODO' AS violation_category
        ,count(DISTINCT c.id) AS citation_count
      FROM violations v
      JOIN citations c ON c.violation_id = v.id
      GROUP BY 1,2,3
      ORDER BY citation_count DESC
      LIMIT 15;
    SQL

    query_results = ActiveRecord::Base.connection.execute(query_string)

    @violations = query_results.to_a

    respond_to do |format|
      format.json { render json: @violations }
    end
  end
end
