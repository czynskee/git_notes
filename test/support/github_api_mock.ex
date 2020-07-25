defmodule GitNotes.GithubAPI.Mock do
  use HTTPoison.Base

  def post_code_for_user_token(code) do
    "token"
  end
end
