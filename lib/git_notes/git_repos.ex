defmodule GitNotes.GitRepos do
  alias GitNotes.GitRepos.GitRepo
  alias GitNotes.Repo

  def list_repos() do

  end

  def list_repos_by_user(id) do

  end

  def get_repo(id) do

  end

  def create_repo(attrs \\ %{}) do
    %GitRepo{}
    |> GitRepo.changeset(attrs)
    |> Repo.insert()
  end

  def delete_repo() do

  end
end
