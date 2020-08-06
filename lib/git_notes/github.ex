defmodule GitNotes.Github do
  alias GitNotes.Notes
  alias GitNotes.Accounts
  alias GitNotes.Accounts.User
  alias GitNotes.GitRepos

  @github_api Application.fetch_env!(:git_notes, :github_api)

  def get_access_token(code) do
    @github_api.get_access_token(code)
  end

  def get_installation_access_token(installation_id) do
    @github_api.get_installation_access_token(installation_id)
  end

  defp retrieve_install_token(installation_id) do
    get_installation_access_token(installation_id)
    |> elem(1)
    |> Map.get("token")
  end

  def get_user(token) do
    @github_api.get_user(token)
    |> elem(1)
  end

  def populate_notes(%GitNotes.GitRepos.GitRepo{} = git_repo) do
    populate_notes(git_repo.id)
  end

  def populate_notes(repo_id) when is_integer(repo_id) do
    %{user: user, repo: repo, token: token} = retrieve_records_for_notes_update(repo_id)

    @github_api.get_repo_contents(token, user, repo)
    |> elem(1)
    |> Enum.map(& &1["name"])
    |> retrieve_and_prepare_files(token, user, repo)
    |> Enum.map(& Map.put &1, "git_repo_id", repo.id)
    |> Enum.each(&(Notes.create_file(&1)))
  end

  defp retrieve_and_prepare_files(files, token, user, repo) when is_list(files) do
    Enum.map(files, fn file ->
      Task.async(@github_api, :get_file_contents, [token, user, repo, file])
    end)
    |> Enum.map(fn task -> Task.await(task) |> elem(1) end)
  end

  def update_notes_files(%User{notes_repo: repo} = user, %{"removed" => removed_files, "added" => added_files, "modified" => modified_files}) do
    token = retrieve_install_token(user.installation_id)

    added_files ++ modified_files
    |> retrieve_and_prepare_files(token, user, repo)
    |> Enum.each(fn file ->
      case Notes.get_file_by(repo.id, %{name: file["name"]}) do
        nil ->
          Map.put(file, "git_repo_id", repo.id)
          |> Notes.create_file()
        existing ->
          Notes.update_file(existing, file)
      end
    end)

    removed_files
    |> Enum.each(fn file ->
      case Notes.get_file_by(repo.id, %{name: file}) do
        nil -> :noop
        existing -> Notes.delete_file(existing)
      end
    end)
  end

  defp retrieve_records_for_notes_update(repo_id) do
    repo = GitRepos.get_repo(repo_id)
    user = Accounts.get_user(repo.user_id)

    token = retrieve_install_token(user.installation_id)

    %{
      user: user,
      repo: repo,
      token: token
    }
  end

end
