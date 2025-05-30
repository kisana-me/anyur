class StripeWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = ENV['STRIPE_SIGNING_SECRET']
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      render json: { error: "Invalid payload" }, status: :bad_request
      return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: "Invalid signature" }, status: :bad_request
      return
    end

    case event.type
    when 'checkout.session.completed'
      session = event.data.object
      handle_checkout_session_completed(session)
    when 'customer.subscription.created'
      subscription = event.data.object
      handle_subscription_created(subscription)
    when 'customer.subscription.updated'
      subscription = event.data.object
      handle_subscription_updated(subscription)
    when 'customer.subscription.deleted'
      subscription = event.data.object
      handle_subscription_deleted(subscription)
    else
      # 他のイベントが到着
    end

    render json: { message: :success }
  end

  private

  def handle_checkout_session_completed(session)
    # account = Account.find_by_sci(session.customer)
    # return unless account
    # stripe_sub = Stripe::Subscription.retrieve(session.subscription)
    # return unless stripe_sub
  end

  def handle_subscription_created(stripe_sub)
    account = Account.find_by(stripe_customer_id: stripe_sub.customer)
    return unless account

    subscription = account.subscriptions.find_or_initialize_by(stripe_subscription_id: stripe_sub.id)
    subscription.assign_attributes(
      stripe_plan_id: stripe_sub['items']['data'][0]['price']['id'],
      status: stripe_sub['status'],
      current_period_start: stripe_sub['items']['data'][0]['current_period_start'] ? Time.at(stripe_sub['items']['data'][0]['current_period_start']) : nil,
      current_period_end: stripe_sub['items']['data'][0]['current_period_end'] ? Time.at(stripe_sub['items']['data'][0]['current_period_end']) : nil,
      cancel_at_period_end: stripe_sub['cancel_at_period_end'],
      canceled_at: stripe_sub['canceled_at'] ? Time.at(stripe_sub['canceled_at']) : nil,
      trial_start_at: stripe_sub['trial_start'] ? Time.at(stripe_sub['trial_start']) : nil,
      trial_end_at: stripe_sub['trial_end'] ? Time.at(stripe_sub['trial_end']) : nil
    )
    subscription.save!
  end

  def handle_subscription_updated(stripe_sub)
    subscription = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
    return unless subscription

    subscription.assign_attributes(
      stripe_plan_id: stripe_sub['items']['data'][0]['price']['id'],
      status: stripe_sub['status'],
      current_period_start: stripe_sub['items']['data'][0]['current_period_start'] ? Time.at(stripe_sub['items']['data'][0]['current_period_start']) : nil,
      current_period_end: stripe_sub['items']['data'][0]['current_period_end'] ? Time.at(stripe_sub['items']['data'][0]['current_period_end']) : nil,
      cancel_at_period_end: stripe_sub['cancel_at_period_end'],
      canceled_at: stripe_sub['canceled_at'] ? Time.at(stripe_sub['canceled_at']) : nil,
      trial_start_at: stripe_sub['trial_start'] ? Time.at(stripe_sub['trial_start']) : nil,
      trial_end_at: stripe_sub['trial_end'] ? Time.at(stripe_sub['trial_end']) : nil
    )
    subscription.save!
  end

  def handle_subscription_deleted(stripe_sub)
    subscription = Subscription.find_by(stripe_subscription_id: stripe_sub.id)
    return unless subscription

    subscription.update!(
      status: :canceled,
      canceled_at: stripe_sub['canceled_at'] ? Time.at(stripe_sub['canceled_at']) : nil,
      current_period_end: stripe_sub['items']['data'][0]['current_period_end'] ? Time.at(stripe_sub['items']['data'][0]['current_period_end']) : nil
    )
  end
end