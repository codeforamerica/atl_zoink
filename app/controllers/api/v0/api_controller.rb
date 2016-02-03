class Api::V0::ApiController < ApplicationController

  # Returns the top most-cited violations.
  #
  # @param params [Hash]
  # @option params [Hash] limit A positive integer number of records to return. Corresponds to a SQL LIMIT clause value. Default is 50.
  #
  # @example [{"violation_id":"1", "violation_code":"40-6-20", "violation_description":"FAIL TO OBEY TRAF CTRL DEVICE", "citation_count":"3469"},{"violation_id":"9", "violation_code":"40-2-8", "violation_description":"NO TAG/ NO DECAL", "citation_count":"2515"},{"violation_id":"11", "violation_code":"40-8-76.1", "violation_description":"SAFETY BELT VIOLATION", "citation_count":"1960"}]
  #
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




  # Returns a histogram of defendant counts per each citation count.
  #
  # @param params [Hash]
  # @option params [Hash] limit A positive integer number of records to return. Corresponds to a SQL LIMIT clause value. Default is 6.
  #
  # @example [{"citation_count":"1","defendant_count":"130706"},{"citation_count":"2","defendant_count":"29159"},{"citation_count":"3","defendant_count":"8987"},{"citation_count":"4","defendant_count":"3509"},{"citation_count":"5","defendant_count":"1409"},{"citation_count":"6","defendant_count":"678"},{"citation_count":"7","defendant_count":"314"},{"citation_count":"8","defendant_count":"170"},{"citation_count":"9","defendant_count":"86"},{"citation_count":"10","defendant_count":"61"},{"citation_count":"11","defendant_count":"31"},{"citation_count":"12","defendant_count":"19"},{"citation_count":"13","defendant_count":"14"},{"citation_count":"14","defendant_count":"5"},{"citation_count":"15","defendant_count":"6"},{"citation_count":"16","defendant_count":"2"},{"citation_count":"17","defendant_count":"2"},{"citation_count":"18","defendant_count":"4"},{"citation_count":"19","defendant_count":"4"},{"citation_count":"21","defendant_count":"1"}]
  #
  def defendant_citation_distribution
    default_limit = 6
    limit = params[:limit].try(:to_i) || default_limit # block sql-injection by converting (malicious) strings to zeros ...
    limit = default_limit if limit <= 0

    sql_string = <<-SQL
      SELECT
        zz.citation_count
        ,count(distinct defendant_full_name) as defendant_count
      FROM (
        SELECT
          c.defendant_full_name
          ,count(DISTINCT c.guid) AS citation_count
        FROM atlanta_citations c
        GROUP BY 1
        ORDER BY 2 DESC
      ) zz
      GROUP BY 1
      ORDER BY 1
      LIMIT #{limit};
    SQL

    result = ActiveRecord::Base.connection.execute(sql_string)

    @citation_distributions = result.to_a

    respond_to do |format|
      format.json { render json: @citation_distributions }
    end
  end
end
