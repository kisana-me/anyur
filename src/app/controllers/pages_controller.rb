class PagesController < ApplicationController
  before_action :require_signin, only: :home

  def index
  end

  def home
  end

  def terms_of_service
    @document = Document.find_by(name_id: "terms_of_service", status: :specific)
  end

  def privacy_policy
    @document = Document.find_by(name_id: "privacy_policy", status: :specific)
  end

  def specified_commercial_transactions
    @document = Document.find_by(name_id: "specified_commercial_transactions", status: :specific)
  end

  def contact
  end
end
