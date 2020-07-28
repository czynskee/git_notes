defmodule GitNotes.GitRepos do
  alias GitNotes.GitRepos.GitRepo
  alias GitNotes.Repo
  import Ecto.Query

  def list_user_repos(%GitNotes.Accounts.User{id: user_id}) do
    user_repos_query(user_id)
    |> Repo.all()
  end

  def user_repos_query(user_id) do
    from r in GitRepo,
    where: r.user_id == ^user_id
  end

  def get_repo(id) do
    Repo.get(GitRepo, id)
  end

  def create_repo(attrs \\ %{}) do
    %GitRepo{}
    |> GitRepo.new_repo_changeset(attrs)
    |> Repo.insert()
  end

  def delete_repo() do

  end
end
