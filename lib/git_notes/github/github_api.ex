defmodule GitNotes.GithubAPI do
  @callback get_access_token(code :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_user(token :: String.t()) :: :error | %{String.t() => String.t()}

  # This is for making API requests on the behalf of a certain installation, even if that user is not currently logged in
  @callback get_installation_access_token(installation_id :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_repo_contents(token :: String.t(), user_id :: Integer.t(), repo_id :: Integer.t()) :: :error | %{String.t() => String.t()}

  @callback get_file_contents(token :: String.t(), user_id :: Integer.t(), repo_id :: Integer.t(), name :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_installations(token :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_installation_repos(token :: String.t()) :: :error | %{String.t() => String.t()}
end
