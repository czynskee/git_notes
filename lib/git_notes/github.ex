defmodule GitNotes.Github do

  @github_api Application.fetch_env!(:git_notes, :github_api)

  def get_access_token(code) do
    @github_api.get_access_token(code)
  end

  def get_user(token) do
    @github_api.get_user(token)
    |> elem(1)
  end
end
