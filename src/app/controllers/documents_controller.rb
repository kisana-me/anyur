class DocumentsController < ApplicationController
  before_action :admin_account, except: [:index, :show]
  before_action :set_document, only: %i[ edit update destroy ]

  def index
    @documents = Document.where(status: 0, deleted: false)
  end

  def show
    @document = Document.find_by(name_id: params.expect(:name_id), status: 0, deleted: false)
  end

  # 以下はadminに移行予定

  def new
    @document = Document.new
  end

  def edit
  end

  def create
    @document = Document.new(document_params)
    if @document.save
      redirect_to @document, notice: "Document was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @document.update(document_params)
      redirect_to @document, notice: "Document was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.update(deleted: true)
    redirect_to documents_path, status: :see_other, notice: "文書を削除しました"
  end

  private

  def set_document
    @document = Document.find(params.expect(:id))
  end

  def document_params
    params.expect(document: [ :name, :name_id, :content, :meta, :status, :deleted ])
  end
end
