defmodule GitNotes.Github do
  alias GitNotes.{Accounts, GitRepos, Notes, Commits}
  alias GitNotes.Accounts.User
  alias GitNotes.GitRepos.GitRepo

  @github_api Application.fetch_env!(:git_notes, :github_api)

  def get_access_token(code) do
    @github_api.get_access_token(code)
  end
  def get_installation_access_token(installation_id) do
    @github_api.get_installation_access_token(installation_id)
  end

  defp retrieve_install_token(%User{} = user) do
    token = get_installation_access_token(user.installation_id) |> elem(1)
    Accounts.update_installation_access_token(user, token)
    token["token"]
  end

  defp retrieve_user_token(user_id) when is_integer(user_id) do
    retrieve_user_token(Accounts.get_user(user_id))
  end

  defp retrieve_user_token(%User{} = user) do
    now = DateTime.now("Etc/UTC") |> elem(1)
    cond do
      user.access_token && user.access_token_expiration > now ->
        user.access_token
      user.installation_access_token && user.installation_access_token_expiration > now ->
        user.installation_access_token
      user.refresh_token && user.refresh_token_expiration > now ->
        refresh_access_token(user)
      true ->
        retrieve_install_token(user)
    end
  end

  defp refresh_access_token(user) do
    credentials = @github_api.refresh_access_token(user)
    Accounts.update_github_credentials(user, credentials)
    credentials["access_token"]
  end

  def get_repo_commits(token, user, repo) do
    @github_api.get_repo_commits(token, user, repo)
  end

  def get_user(token) do
    @github_api.get_user(token)
  end

  def get_installations(token) do
    @github_api.get_installations(token)
  end

  def get_installation_repos(installation_id) do
    retrieve_user_token(Accounts.get_user_by(%{installation_id: installation_id}))
    |> @github_api.get_installation_repos()
  end

  def commit_and_push_file(payload, content) do
    user = Accounts.get_user(payload[:user_id])
    notes_repo = GitRepos.get_repo(user.notes_repo_id)
    token = retrieve_user_token(user)

    {:ok, head} = @github_api.get_repo_master_head(token, user, notes_repo)

    {:ok, last_commit} = @github_api.get_commit(token, user, notes_repo, get_in(head, ["object", "sha"]))

    {:ok, last_commit_tree} = @github_api.get_tree(token, user, notes_repo, get_in(last_commit, ["tree", "sha"]))

    date_string = Date.to_iso8601(payload.date)

    new_tree_payload = %{
      "base_tree" => last_commit_tree["sha"],
      "tree" => [
        %{
          "path" => date_string <> ".md",
          "mode" => "100644", # blob
          "type" => "blob",
          "content" => content
        }
      ]
    }

    {:ok, updated_tree} = @github_api.post_tree(token, user, notes_repo, new_tree_payload)

    new_commit_payload = %{
      "message" => "Notes commit for #{date_string}.",
      "tree" => updated_tree["sha"],
      "parents" => [last_commit["sha"]]
    }

    {:ok, new_commit} = @github_api.post_commit(token, user, notes_repo, new_commit_payload)

    @github_api.patch_master_head_commit_reference(token, user, notes_repo, new_commit["sha"])
  end


  def populate_commits(%User{} = user) do
    repos = GitRepos.list_user_repos(user)
    token = retrieve_user_token(user)

    repos
    |> Enum.map(fn repo ->
      {repo, Task.async(@github_api, :get_repo_commits, [token, user, repo])}
    end)
    |> Enum.map(fn {repo, task} -> {repo, Task.await(task) |> elem(1)} end)
    |> Enum.each(fn {repo, commits} ->
      commits
      |> filter_commits()
      |> Enum.map(& Map.put &1, "git_repo_id", repo.id)
      |> Enum.map(& Map.put &1, "author", get_in(&1, ["commit", "author", "name"]))
      |> Enum.map(& Map.put &1, "commit_date",
        get_in(&1, ["commit", "author", "date"])
        |> String.split("T") |> Enum.at(0) |> Date.from_iso8601() |> elem(1))
      |> Enum.map(& Map.put &1, "message", get_in(&1, ["commit", "message"]))
      |> Enum.map(& Map.put &1, "distinct", true)
      |> Enum.map(& Map.put &1, "ref", "unknown")
      |> Enum.each(& Commits.create_commit(&1))
    end)
  end

  defp filter_commits(commits) when is_list(commits) do
    commits
    |> Enum.filter(& &1["message"] !== "Git Repository is empty.")
  end

  defp filter_commits(commits) do
    filter_commits([commits])
  end

  @spec populate_notes(integer | GitRepo.t()) :: :ok
  def populate_notes(%GitRepo{} = git_repo) do
    populate_notes(git_repo.id)
  end

  def populate_notes(repo_id) when is_integer(repo_id) do
    %{user: user, repo: repo, token: token} = retrieve_records_for_notes_update(repo_id)

    @github_api.get_repo_contents(token, user, repo)
    |> elem(1)
    |> Enum.map(& &1["name"])
    |> retrieve_and_prepare_files(token, user, repo)
    |> Enum.map(& Map.put &1, "git_repo_id", repo.id)
    |> Enum.each(&(Notes.create_or_update_file(&1)))

    GitNotesWeb.Endpoint.broadcast("user: #{repo.user_id}", "updated_file", %{})
  end

  defp retrieve_and_prepare_files(files, token, user, repo) when is_list(files) do
    Enum.map(files, fn file ->
      Task.async(@github_api, :get_file_contents, [token, user, repo, file])
    end)
    |> Enum.map(fn task -> Task.await(task) |> elem(1) end)
  end

  def update_notes_files(%User{notes_repo: repo} = user, %{"removed" => removed_files, "added" => added_files, "modified" => modified_files}) do
    token = retrieve_user_token(user)

    added_files ++ modified_files
    |> retrieve_and_prepare_files(token, user, repo)
    |> Enum.each(fn file ->
      file
      |> Map.put("git_repo_id", repo.id)
      |> Notes.create_or_update_file()
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

    token = retrieve_user_token(user)

    %{
      user: user,
      repo: repo,
      token: token
    }
  end

end
