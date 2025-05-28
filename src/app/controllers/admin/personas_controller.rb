class Admin::PersonasController < Admin::ApplicationController
  def index
    @personas = Persona.all
  end

  private
end
