class Api::V0::ApiController < ApplicationController

  # Returns the top most-cited violations.
  #
  # @param params [Hash]
  # @option params [Hash] limit A positive integer number of records to return. Corresponds to a SQL LIMIT clause value. Default is 50.
  #
  # @example [{"violation_id":"1", "violation_code":"40-6-20", "violation_description":"FAIL TO OBEY TRAF CTRL DEVICE", "citation_count":"3469"},{"violation_id":"9", "violation_code":"40-2-8", "violation_description":"NO TAG/ NO DECAL", "citation_count":"2515"},{"violation_id":"11", "violation_code":"40-8-76.1", "violation_description":"SAFETY BELT VIOLATION", "citation_count":"1960"}]
  def top_violations
    default_limit = 50
    limit = params[:limit].try(:to_i) || default_limit # block sql-injection by converting (malicious) strings to zeros ...
    limit = default_limit if limit <= 0

    query_string =<<-SQL
      SELECT
        v.id AS violation_id
        ,v.code AS violation_code
        ,v.description AS violation_description
        ,count(DISTINCT cv.citation_guid) AS citation_count
      FROM atlanta_violations v
      JOIN atlanta_citation_violations cv ON v.code = cv.violation_code
      GROUP BY 1,2,3
      ORDER BY citation_count DESC
      LIMIT #{limit};
    SQL

    query_results = ActiveRecord::Base.connection.execute(query_string)

    @violations = query_results.to_a

    respond_to do |format|
      format.json { render json: @violations }
    end
  end


  def citations_per_defendant
    @citation_distributions = [
      {"citation_count":1, "defendant_count":100000},
      {"citation_count":2, "defendant_count":40000},
      {"citation_count":3, "defendant_count":15000},
      {"citation_count":4, "defendant_count":6000},
      {"citation_count":5, "defendant_count":2000},
      {"citation_count":6, "defendant_count":700},
      {"citation_count":7, "defendant_count":100},
    ]

    respond_to do |format|
      format.json { render json: @citation_distributions }
    end
  end
end
