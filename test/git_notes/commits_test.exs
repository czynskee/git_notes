defmodule GitNotes.CommitsTest do
  use GitNotes.DataCase, async: true

  alias GitNotes.Commits
  alias GitNotes.Commits.Commit

  @commit_date Date.utc_today()

  @valid_attrs %{
    "sha" => "a654df65aer",
    "message" => "commit message",
    "distinct" => true,
    "author" => "czynskee",
    "commit_date" => @commit_date,
    "git_repo_id" => 12345,
    "ref" => "refs/head/master"
  }

  @invalid_attrs %{}

  test "create commit with valid attrs" do
    %{repo: repo, user: _user} = fixtures()

    commit = Commits.create_commit!(@valid_attrs)

    assert commit = Repo.get(Commit, commit.id)

    assert commit.message == "commit message"
    assert commit.distinct == true
    assert commit.author == "czynskee"
    assert commit.commit_date == @commit_date
    assert commit.git_repo_id == repo.id
    assert commit.ref == "refs/head/master"
    assert commit.sha == "a654df65aer"
  end

  test "create commit with invalid attrs" do
    assert catch_error Commits.create_commit!(@invalid_attrs)
  end

  test "list all commits by repo and by user" do
    %{repo: repo, user: user} = fixtures()

    commit1 = Commits.create_commit!(@valid_attrs)
    commit2 = Commits.create_commit!(%{@valid_attrs | "sha" => "a65sd74r8we", "message" => "different message"})

    commits = Commits.list_repo_commits(repo)
    assert commit1 in commits
    assert commit2 in commits

    user_commits = Commits.list_user_commits(user)

    assert commit1 in user_commits
    assert commit2 in user_commits
  end

end
