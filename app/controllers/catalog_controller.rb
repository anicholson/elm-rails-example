class CatalogController < ApplicationController
  before_action :check_format

  def index
    render json: CatalogRepository.get
  end

  def check_format
    render :plain => '', :status => 406 unless params[:format] == 'json' || request.headers["Accept"] =~ /json/
  end
end
