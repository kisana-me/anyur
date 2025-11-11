class InquiriesController < ApplicationController
  skip_before_action :require_signin

  def new
    @inquiry = Inquiry.new((session[:inquiry_params] || {}).to_h.except("link_account"))
    @services = Service.is_normal
  end

  def confirm
    @inquiry = Inquiry.new(inquiry_params)
    @services = Service.is_normal
    unless verify_turnstile(params["cf-turnstile-response"])
      @inquiry.errors.add(:base, :failed_captcha)
      return render :new, status: :unprocessable_entity
    end
    unless @inquiry.valid?
      return render :new, status: :unprocessable_entity
    end
    session[:inquiry_params] = inquiry_params.to_h.merge(
      "link_account" => (params[:inquiry][:link_account] == "1")
    )
  end

  def create
    @inquiry = Inquiry.new((session[:inquiry_params] || {}).to_h.except("link_account"))
    @services = Service.is_normal

    if session[:inquiry_params].to_h["link_account"] && @current_account
      @inquiry.account = @current_account
    end

    @inquiry.service = Service.is_normal.find_by(aid: session[:inquiry_params].to_h["service_aid"])

    if @inquiry.save
      session.delete(:inquiry_params)
      flash.now[:notice] = "お問い合わせを承りました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def inquiry_params
    params.expect(
      inquiry: [
        :service_aid,
        :subject,
        :content,
        :name,
        :email
      ]
    )
  end
end
