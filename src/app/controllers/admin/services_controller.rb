class Admin::ServicesController < Admin::ApplicationController
  before_action :set_service, only: %i[ show edit update destroy ]

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
    @service.update(deleted: true)
      redirect_to admin_services_path, status: :see_other, notice: "サービスを削除しました"
  end

  private

  def set_service
    @service = Service.find(params.expect(:id))
  end

  def service_params
    params.expect(service: [
      :name, :name_id, :summary, :description, :description_cache,
      :host, :status, :deleted
    ])
  end
end
