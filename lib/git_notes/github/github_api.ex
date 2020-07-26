defmodule GitNotes.GithubAPI do
  @callback get_access_token(code :: String.t()) :: :error | %{String.t() => String.t()}
  @callback get_user(token :: String.t()) :: :error | %{String.t() => String.t()}
end
