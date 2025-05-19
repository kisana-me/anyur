class PagesController < ApplicationController
  before_action :signedin_account, only: :home

  def index
  end

  def home
  end

  def terms_of_service
    @document = Document.find_by(name_id: 'terms_of_service', status: :specific, deleted: false)
  end

  def privacy_policy
    @document = Document.find_by(name_id: 'privacy_policy', status: :specific, deleted: false)
  end

  def contact
  end
end
