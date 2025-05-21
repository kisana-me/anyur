class Admin::DocumentsController < Admin::ApplicationController
  before_action :set_document, only: %i[ show edit update destroy ]

  def index
    @documents = Document.all
  end

  def show
  end

  def new
    @document = Document.new
  end

  def edit
  end

  def create
    @document = Document.new(document_params)
    if @document.save
      redirect_to admin_document_path(@document), notice: "文書を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @document.update(document_params)
      redirect_to admin_document_path(@document), notice: "文書を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.update(deleted: true)
    redirect_to admin_documents_path, status: :see_other, notice: "文書を削除しました"
  end

  private

  def set_document
    @document = Document.find(params.expect(:id))
  end

  def document_params
    params.expect(document: [
      :name, :name_id, :summary, :content, :content_cache,
      :published_at, :status, :deleted
    ])
  end
end
