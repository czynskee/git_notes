defmodule GitNotes.Github do

  @github_api Application.fetch_env!(:git_notes, :github_api)

  def get_access_token(code) do
    @github_api.post_code_for_user_token(code)
  end
end
