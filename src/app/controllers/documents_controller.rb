class DocumentsController < ApplicationController

  def index
    @documents = Document.where(status: :published, deleted: false)
  end

  def show
    @document = Document.find_by(name_id: params.expect(:name_id), status: :published, deleted: false)
  end
end
