class SubscriptionsController < ApplicationController
  before_action :signedin_account
  before_action :email_verified_account
  before_action :redirect_if_already_subscribed, only: [:new, :create]

  def index
  end

  def customer_portal
    if @current_account.stripe_customer_id.blank?
      flash[:alert] = "購入をしたことがありません"
      redirect_to subscriptions_path
    end
    portal_session = Stripe::BillingPortal::Session.create({
      customer: @current_account.stripe_customer_id,
      return_url: home_url
    })
    redirect_to portal_session.url, allow_other_host: true, status: :see_other
  end

  def new
    @price_id = ENV['STRIPE_PRICE_ID']
  end

  def create
    price_id = params[:price_id]

    # ユーザーがStripe顧客でない場合は作成
    if @current_account.stripe_customer_id.blank?
      customer = Stripe::Customer.create({
        email: @current_account.email,
        name: @current_account.name,
        metadata: { id: @current_account.id }
      })
      @current_account.update(stripe_customer_id: customer.id)
    end

    begin
      session = Stripe::Checkout::Session.create({
        customer: @current_account.stripe_customer_id,
        payment_method_types: ['card'],
        line_items: [{
          price: price_id,
          quantity: 1,
        }],
        mode: 'subscription',
        success_url: success_subscriptions_url + '?session_id={CHECKOUT_SESSION_ID}',
        cancel_url: cancel_subscriptions_url,
      })

      redirect_to session.url, allow_other_host: true, status: :see_other
    rescue Stripe::StripeError => e
      flash[:alert] = "エラーが発生しました: #{e.message}"
      redirect_to new_subscription_path
    end
  end

  def success
    # 支払い成功時の処理
    # session_id = params[:session_id]
    # checkout_session = Stripe::Checkout::Session.retrieve(session_id)
    # subscription_id = checkout_session.subscription
    # current_user.update(stripe_subscription_id: subscription_id, subscription_status: 'active') # 例
    flash[:info] = "サブスクリプションが開始されました！"
    redirect_to subscriptions_url
  end

  def cancel
    # 支払いキャンセル時の処理
    flash[:alert] = "サブスクリプションの登録がキャンセルされました"
    redirect_to subscriptions_url
  end

  private

  def redirect_if_already_subscribed
    if @current_account.active_subscription.present?
      flash[:alert] = "すでに有効なサブスクリプションにご登録済みです"
      redirect_to subscriptions_path
    end
  end
end