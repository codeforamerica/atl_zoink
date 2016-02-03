class ChartsController < ApplicationController
  LOADING_MESSAGE = " ... loading ... this might take a few seconds :-)"

  def index
    #code
  end

  def top_violations
    @loading_message = LOADING_MESSAGE
  end

  def defendant_citation_distribution
    @loading_message = LOADING_MESSAGE
  end
end
