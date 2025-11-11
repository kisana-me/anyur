class DocumentsController < ApplicationController
  skip_before_action :require_signin

  def index
    @documents = Document.is_normal.is_opened
  end

  def show
    @document = Document.is_normal.is_opened.find_by!(name_id: params.expect(:name_id))
  end
end
