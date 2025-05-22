class InquiriesController < ApplicationController
  def new
    @inquiry = Inquiry.new
    @services = Service.where(deleted: false)#status
  end

  def create
    @inquiry = Inquiry.new(inquiry_params)
    @services = Service.where(deleted: false)#status
    unless verify_turnstile(params["cf-turnstile-response"])
      @inquiry.errors.add(:base, :failed_captcha)
      return render :new, status: :unprocessable_entity
    end
    if (params[:inquiry][:account] == "1") && @current_account
      @inquiry.account = @current_account
    end
    if @inquiry.save
      flash.now[:notice] = "お問い合わせを承りました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def inquiry_params
    params.expect(inquiry: [ :service_id, :subject, :summary, :content, :name, :email ])
  end
end
