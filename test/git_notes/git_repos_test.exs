defmodule GitNotes.GitReposTest do
  use GitNotes.DataCase, async: true

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

    assert %GitRepo{} = repo = GitRepos.create_repo(@valid_attrs)

    assert repo.name == "cool-repo"
    assert repo.id == @valid_attrs.id

    query_repo = GitNotes.Repo.get(GitRepo, repo.id)

    GitRepos.get_repo(repo.id)

    assert query_repo.id == repo.id
    assert query_repo.user_id == user.id
  end

  test "create repo with invalid attrs" do
    assert catch_error GitRepos.create_repo(@invalid_attrs)
  end

  test "list user repos" do
    user = user_fixture()

    repo1 = GitRepos.create_repo(@valid_attrs)
    repo2 = GitRepos.create_repo(%{@valid_attrs | name: "different-repo", id: 1234564687})
    repo3 = GitRepos.create_repo(%{@valid_attrs | name: "different-repo-2", id: 496871})

    all_repos = GitRepos.list_user_repos(user)

    assert length(all_repos) == 3
    assert repo1 in all_repos
    assert repo2 in all_repos
    assert repo3 in all_repos
  end

  test "create duplicate repos" do
    user_fixture()

    GitRepos.create_repo(@valid_attrs)
    assert catch_error GitRepos.create_repo(@valid_attrs)
  end

  test "delete repo with repo struct" do
    %{repo: repo} = fixtures()

    repo = GitRepos.delete_repo(repo)

    assert GitRepos.get_repo(repo.id) == nil

  end

  test "delete repo with repo id" do
    %{repo: repo} = fixtures()

    repo = GitRepos.delete_repo(repo.id)

    assert GitRepos.get_repo(repo.id) == nil

  end

  test "update a repos name" do
    %{repo: repo} = fixtures()
    repo = GitRepos.update_repo(repo, %{name: "newname"})

    assert GitRepos.get_repo(repo.id).name == "newname"
  end

  test "update a repos name without providing the repo" do
    %{repo: repo} = fixtures()

    repo = GitRepos.update_repo(%{"id" => repo.id, "name" => "newname"})

    assert GitRepos.get_repo(repo.id).name == "newname"
  end


end
