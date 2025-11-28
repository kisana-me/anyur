class ServicesController < ApplicationController
  def index
    @services = Service.is_normal
  end

  def show
    @service = Service.is_normal.find_by!(name_id: params.expect(:name_id))
  end
end
