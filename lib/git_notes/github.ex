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

  def get_user(token) do
    @github_api.get_user(token)
    |> elem(1)
  end

  def populate_notes(%Notes.NotesRepo{} = notes_repo) do
    user = Accounts.get_user(notes_repo.user_id)
    repo = GitRepos.get_repo(notes_repo.repo_id)

    token =
    get_installation_access_token(user.installation_id)
    |> elem(1)
    |> Map.get("token")

    @github_api.get_repo_contents(token, user, repo)
    |> elem(1)
    |> Enum.map(fn file ->
      Task.async(@github_api, :get_file_contents, [token, user, repo, file["name"]])
    end)
    |> Enum.map(fn task -> Task.await(task) |> elem(1) end)
    |> Enum.map(&(Map.put(&1, "file_name", &1["name"])))
    |> Enum.map(&(Map.put(&1, "notes_repo_id", notes_repo.id)))
    |> Enum.each(&(Notes.create_file(&1)))
  end


end
