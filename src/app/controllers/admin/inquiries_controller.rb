class Admin::InquiriesController < Admin::ApplicationController
  def index
    @inquiries = Inquiry.all
  end

  private
end
