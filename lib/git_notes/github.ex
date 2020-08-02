defmodule GitNotes.Github do
  alias GitNotes.Notes
  alias GitNotes.Accounts
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

  def populate_notes(%Notes.NotesRepo{} = notes_repo) do
    %{user: user, repo: repo, token: token} = retrieve_records_for_notes_update(notes_repo)

    @github_api.get_repo_contents(token, user, repo)
    |> elem(1)
    |> retrieve_and_prepare_files(token, user, repo, notes_repo)
    |> Enum.each(&(Notes.create_file(&1)))
  end

  defp retrieve_and_prepare_files(files, token, user, repo, notes_repo) when is_list(files) do
    Enum.map(files, fn file ->
      Task.async(@github_api, :get_file_contents, [token, user, repo, file["name"]])
    end)
    |> Enum.map(fn task -> Task.await(task) |> elem(1) end)
    |> Enum.map(&(Map.put(&1, "file_name", &1["name"])))
    |> Enum.map(&(Map.put(&1, "notes_repo_id", notes_repo.id)))
  end

  def update_notes_files(notes_repo, %{"removed" => removed_files, "added" => added_files, "modified" => modified_files}) do
    %{user: user, repo: repo, token: token} = retrieve_records_for_notes_update(notes_repo)

    added_files ++ modified_files
    |> Enum.map(fn file_name ->
      %{"name" => file_name}
    end)
    |> retrieve_and_prepare_files(token, user, repo, notes_repo)
    |> Enum.each(fn file ->
      case Notes.get_repo_file_by(notes_repo, %{file_name: file["file_name"]}) do
        nil -> Notes.create_file(file)
        existing -> Notes.update_file(existing, file)
      end
    end)

    removed_files
    |> Enum.each(fn file ->
      case Notes.get_repo_file_by(notes_repo, %{file_name: file}) do
        nil -> :noop
        existing -> Notes.delete_file(existing)
      end
    end)
  end

  defp retrieve_records_for_notes_update(%Notes.NotesRepo{} = notes_repo) do
    user = Accounts.get_user(notes_repo.user_id)
    repo = GitRepos.get_repo(notes_repo.repo_id)

    token = retrieve_install_token(user.installation_id)

    %{
      user: user,
      repo: repo,
      token: token
    }
  end

end
