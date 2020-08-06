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

  def create_repo(attrs) do
    %GitRepo{}
    |> GitRepo.new_repo_changeset(attrs)
    |> Repo.insert!()
  end

  def delete_repo(repo_id) when is_integer(repo_id) do
    get_repo(repo_id)
    |> delete_repo()
  end

  def delete_repo(%GitRepo{} = repo) do
    Repo.delete!(repo)
  end

  def update_repo(%GitRepo{} = repo, attrs) do
    repo
    |> GitRepo.changeset(attrs)
    |> Repo.update!()
  end

  def update_repo(%{"id" => id} = attrs) do
    get_repo(id)
    update_repo(get_repo(id), attrs)
  end

end
