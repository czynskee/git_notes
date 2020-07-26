defmodule GitNotesWeb.UserView do
  use GitNotesWeb, :view
  @app_name Application.fetch_env!(:git_notes, :public_app_name)

  def get_app_name() do
    @app_name
  end

end
