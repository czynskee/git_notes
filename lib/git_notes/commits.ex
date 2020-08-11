defmodule GitNotes.Commits do
  alias GitNotes.Commits.Commit
  alias GitNotes.GitRepos
  alias GitNotes.Repo
  import Ecto.Query


  def list_user_commits(%GitNotes.Accounts.User{id: user_id}) do
    list_user_commits(user_id)
  end

  def list_user_commits(user_id) when is_integer(user_id) do
    user_commits_query(user_id)
    |> Repo.all
  end

  def user_commits_query(user_id) do
    (from c in Commit,
    join: r in GitRepos.GitRepo, on: r.id == c.git_repo_id,
    where: r.user_id == ^user_id)
  end

  def list_repo_commits(%GitNotes.GitRepos.GitRepo{id: repo_id}) do
    repo_commits_query(repo_id)
    |> Repo.all
  end

  def get_commits_by_date(user_id, date) do
    query = user_commits_query(user_id)
    (from c in query,
    where: c.commit_date == ^date,
    order_by: [desc: c.commit_date])
    |> Repo.all
  end

  def repo_commits_query(repo_id) do
    from c in Commit,
    where: c.git_repo_id == ^repo_id
  end

  def create_commit!(attrs) do
    %Commit{}
    |> Commit.changeset(attrs)
    |> Repo.insert!()
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
