defmodule GitNotesWeb.UserView do
  use GitNotesWeb, :view
  @app_name Application.fetch_env!(:git_notes, :public_app_name)

  def get_app_name() do
    @app_name
  end

  def get_notes_repo(repos, user) do
    Enum.find(repos, & &1.id == user.notes_repo_id)
  end

end
