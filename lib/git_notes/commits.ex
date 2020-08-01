defmodule GitNotes.Commits do
  alias GitNotes.Commits.Commit
  alias GitNotes.GitRepos
  alias GitNotes.Repo
  import Ecto.Query


  def list_commits_by_user(%GitNotes.Accounts.User{id: user_id}) do
    (from c in Commit,
    join: r in GitRepos.GitRepo, on: r.id == c.git_repo_id,
    where: r.user_id == ^user_id)
    |> Repo.all
  end

  def list_commits_by_repo(%GitNotes.GitRepos.GitRepo{id: repo_id}) do
    repo_commits_query(repo_id)
    |> Repo.all
  end

  def repo_commits_query(repo_id) do
    from c in Commit,
    where: c.git_repo_id == ^repo_id
  end

  def create_commit(attrs) do
    %Commit{}
    |> Commit.changeset(attrs)
    |> Repo.insert()
  end

  def get_commit(id) do
    Repo.get(Commit, id)
  end

end
