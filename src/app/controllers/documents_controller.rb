class DocumentsController < ApplicationController
  skip_before_action :require_signin

  def index
    @documents = Document.where(visibility_status: :published, deleted: false)
  end

  def show
    @document = Document.find_by!(name_id: params.expect(:name_id), visibility_status: :published, deleted: false)
  end
end
