defmodule GitNotes.GitReposTest do
  use GitNotes.DataCase

  alias GitNotes.GitRepos
  alias GitNotes.GitRepos.GitRepo

  @valid_attrs %{
    name: "cool-repo",
    user_id: 123456,
    id: 987654
  }

  @invalid_attrs %{}

  test "create repo with valid attrs" do
    user = user_fixture()

    assert {:ok, %GitRepo{} = repo} = GitRepos.create_repo(@valid_attrs)

    assert repo.name == "cool-repo"
    assert repo.id == @valid_attrs.id

    query_repo = GitNotes.Repo.get(GitRepo, repo.id, preload: [:user])

    assert query_repo.id == repo.id
    assert query_repo.user_id == user.id

  end


end
