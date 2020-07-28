defmodule GitNotes.GithubAPI do
  @callback get_access_token(code :: String.t()) :: :error | %{String.t() => String.t()}

  # This is for identifying logged in users. This also allows us to make API requests on their behalf.
  @callback get_user(token :: String.t()) :: :error | %{String.t() => String.t()}

  # This is for making API requests on the behalf of a certain installation, even if that user is not currently logged in
  @callback get_installation_access_token(installation_id :: String.t()) :: :error | %{String.t() => String.t()}
end
