class ServicesController < ApplicationController
  skip_before_action :require_signin

  def index
    @services = Service.where(deleted: false)#status
  end

  def show
    @service = Service.find_by!(name_id: params.expect(:name_id), deleted: false)#status
  end
end
