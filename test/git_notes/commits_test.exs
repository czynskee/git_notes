defmodule GitNotes.CommitsTest do
  use GitNotes.DataCase, async: true

  alias GitNotes.Commits
  alias GitNotes.Commits.Commit

  @commit_date DateTime.now("Etc/UTC") |> elem(1) |> DateTime.truncate(:second)

  @valid_attrs %{
    "sha" => "a654df65aer",
    "message" => "commit message",
    "distinct" => true,
    "author" => "czynskee",
    "commit_date" => @commit_date,
    "git_repo_id" => 12345
  }

  @invalid_attrs %{}

  test "create commit with valid attrs" do
    repo = repo_fixture()

    assert {:ok, commit} = Commits.create_commit(@valid_attrs)

    assert commit = Repo.get(Commit, commit.id)

    assert commit.message == "commit message"
    assert commit.distinct == true
    assert commit.author == "czynskee"
    assert commit.commit_date == @commit_date
    assert commit.git_repo_id == repo.id
  end

  test "create commit with invalid attrs" do
    assert {:error, _reason} = Commits.create_commit(@invalid_attrs)
  end

  test "list all commits by repo and by user" do
    repo = repo_fixture()

    {:ok, commit1} = Commits.create_commit(@valid_attrs)
    {:ok, commit2} = Commits.create_commit(%{@valid_attrs | "sha" => "a65sd74r8we", "message" => "different message"})

    commits = Commits.list_commits_by_repo(repo)
    assert commit1 in commits
    assert commit2 in commits

    user = GitNotes.Accounts.get_user(repo.user_id)

    user_commits = Commits.list_commits_by_user(user)

    assert commit1 in user_commits
    assert commit2 in user_commits
  end

  test "list all commits by user" do

  end
end
