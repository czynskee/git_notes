defmodule GitNotes.GithubAPI do
  @http_adapter Application.fetch_env!(:git_notes, :http_adapter)

  @type response :: @http_adapter.Response.t() | @http_adapter.AsyncResponse.t()

  @callback post_code_for_user_token(code :: String.t()) :: response
end
