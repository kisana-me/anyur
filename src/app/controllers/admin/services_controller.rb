class Admin::ServicesController < Admin::ApplicationController
  before_action :set_service, only: %i[ show edit create_client_secret update destroy ]

  def index
    @services = Service.all
  end

  def show
  end

  def new
    @service = Service.new
  end

  def edit
  end

  def create_client_secret
    @client_secret = @service.generate_token(params[:expires_in].to_i, "client_secret")
    if @service.save
      # 画面表示
    else
      flash.now[:alert] = "client_secretの発行に失敗しました"
      render :edit, status: :unprocessable_entity
    end
  end

  def create
    @service = Service.new(service_params)
    if @service.save
      redirect_to admin_service_path(@service), notice: "サービスを作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @service.update(service_params)
      redirect_to admin_service_path(@service), notice: "サービスを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service.update(status: :deleted)
      redirect_to admin_services_path, status: :see_other, notice: "サービスを削除しました"
  end

  private

  def set_service
    @service = Service.find(params.expect(:id))
  end

  def service_params
    service_parameters = params.require(:service).permit(
      :name, :name_id, :summary, :description,
      :host, :redirect_uris, :scopes, :meta, :status
    )
    service_parameters[:scopes] = JSON.parse(service_parameters[:scopes]) if service_parameters[:scopes].is_a?(String)
    service_parameters[:redirect_uris] = JSON.parse(service_parameters[:redirect_uris]) if service_parameters[:redirect_uris].is_a?(String)
    service_parameters
  end
end
