class SubscriptionsController < ApplicationController
  before_action :redirect_if_already_subscribed, only: [:create]

  def index
    @subscription = @current_account.active_subscription
    @subscriptions = @current_account.subscriptions.order(created_at: :desc)
  end

  def customer_portal
    if @current_account.stripe_customer_id.blank?
      flash[:alert] = "購入をしたことがありません"
      redirect_to subscriptions_path
    end
    portal_session = Stripe::BillingPortal::Session.create({
      customer: @current_account.stripe_customer_id,
      return_url: subscriptions_url
    })
    redirect_to portal_session.url, allow_other_host: true, status: :see_other
  end

  def new
    @subscription = @current_account.active_subscription
  end

  def create
    @subscription = @current_account.active_subscription
    return render :new, alert: "既にサブスクリプションを開始しています" if @subscription
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
    flash[:notice] = "サブスクリプションが開始されました！"
    redirect_to subscriptions_url
  end

  def cancel
    # 支払いキャンセル時の処理
    flash[:alert] = "サブスクリプションの登録がキャンセルされました"
    redirect_to subscriptions_url
  end

  def change
    @subscription = @current_account.active_subscription
    unless @subscription
      return render :new, alert: "継続中のサブスクリプションがありません"
    end
    price_id = params[:price_id]
    subscription = Stripe::Subscription.retrieve(@subscription.stripe_subscription_id)

    unless @subscription.stripe_subscription_id == subscription.id
      return render :new, alert: "サブスクリプションに不整合が生じました お問い合わせください"
    end

    # サブスクリプションを新プランへ更新
    updated_subscription = Stripe::Subscription.update(
      subscription.id,
      {
        items: [{
          id: subscription.items.data[0].id,
          price: price_id
        }],
        proration_behavior: "create_prorations"
      }
    )

    # ここで即時課金を行うために、未決済の請求書を作成
    upcoming_invoice = Stripe::Invoice.create({
      customer: subscription.customer,
      subscription: subscription.id,
      collection_method: "charge_automatically"
    })

    # 請求書を確定し、即時支払い
    finalized_invoice = Stripe::Invoice.finalize_invoice(upcoming_invoice.id)
    paid_invoice = Stripe::Invoice.pay(finalized_invoice.id)

    redirect_to subscriptions_path, notice: "プランをアップグレードしました"
  rescue Stripe::StripeError => e
    redirect_to subscriptions_path, alert: "エラー: #{e.message}"
  rescue => e
    logger.error e.full_message
    redirect_to subscriptions_path, alert: "予期せぬエラーが発生しました: #{e.message}"
  end

  private

  def redirect_if_already_subscribed
    if @current_account.active_subscription.present?
      flash[:alert] = "すでに有効なサブスクリプションにご登録済みです"
      redirect_to subscriptions_path
    end
  end
end