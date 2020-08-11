defmodule GitNotes.GithubAPI do
  alias GitNotes.Accounts.User
  alias GitNotes.GitRepos.GitRepo

  @callback post_blob(token :: String.t(), user :: %User{}, repo :: %GitRepo{}, blob_content :: String.t()) :: :error | %{String.t() => String.t()}

  @callback post_tree(token :: String.t(), user :: %User{}, repo :: %GitRepo{}, tree :: String.t()) :: :error | %{String.t() => String.t()}

  @callback post_commit(token :: String.t(), user:: %User{}, repo :: %GitRepo{}, commit :: String.t()) :: :error | %{String.t() => String.t()}

  @callback patch_master_head_commit_reference(token :: String.t(), user:: %User{}, repo :: %GitRepo{}, sha :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_commit(token :: String.t(), user :: %User{}, repo :: %GitRepo{}, sha :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_tree(token :: String.t(), user :: %User{}, repo :: %GitRepo{}, sha :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_access_token(code :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_user(token :: String.t()) :: :error | %{String.t() => String.t()}

  # This is for making API requests on the behalf of a certain installation, even if that user is not currently logged in
  @callback get_installation_access_token(installation_id :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_repo_contents(token :: String.t(), user :: %User{}, repo :: %GitRepo{}) :: :error | %{String.t() => String.t()}

  @callback get_file_contents(token :: String.t(), user :: %User{}, repo :: %GitRepo{}, name :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_installations(token :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_installation_repos(token :: String.t()) :: :error | %{String.t() => String.t()}

  @callback get_repo_commits(token :: String.t(), user :: %User{}, repo :: %GitRepo{}) :: :error | %{String.t() => String.t()}

  @callback refresh_access_token(user :: %User{}) :: :error | %{String.t() => String.t()}

  @callback get_repo_master_head(token :: String.t(), user :: %User{}, repo :: %GitRepo{}) :: :error | %{String.t() => String.t()}

end
