defmodule GitNotes.TestHelpers do
  alias GitNotes.Accounts
  alias GitNotes.GitRepos
  alias GitNotes.Notes

  @app_id Application.fetch_env!(:git_notes, :github_app_id)

  def user_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      installation_id: 123,
      id: 123456,
      refresh_token: "456",
      login: "czynskee",
      refresh_token_expiration: DateTime.now("Etc/UTC") |> elem(1) |> DateTime.add(60 * 60 * 24 * 30 * 3, :second)
    })
    |> Accounts.register_user()
    |> elem(1)
  end

  def repo_fixture(attrs \\ %{}, opts \\ []) do
    if is_nil(opts[:create_user]) or opts[:create_user] do
      user_fixture()
    end

    attrs
    |> Enum.into(%{
      "id" => 12345,
      "name" => "git_notes",
      "private" => true,
      "user_id" => 123456
    })
    |> GitRepos.create_repo()
    |> elem(1)
  end

  def notes_repo_fixture(user, repo) do
    Notes.create_notes_repo(%{
      user_id: user.id, repo_id: repo.id
    })
    |> elem(1)
  end

  def fixtures() do
    repo = repo_fixture()
    user = Accounts.get_user(repo.user_id)
    %{user: user, repo: repo}
  end

  def create_installation_payload() do
    %{
      "action" => "created",
      "installation" => %{
        "id" => 123,
        "app_id" => @app_id,
        "account" => %{
          "login" => "czynskee",
          "id" => 123456
        }
       },
      "repositories" => [
        %{
          "id" => 12345,
          "name" => "git_notes",
          "private" => true,
        },
        %{
          "id" => 678910,
          "name" => "cool-repo",
          "private" => false
        }
        ]
      }
  end

  def delete_installation_payload() do
    %{create_installation_payload() | "action" => "deleted"}
  end

  def create_repo_payload() do
    %{
      "action" => "created",
      "repository" => %{
        "id" => 12345,
        "name" => "new-repo",
        "private" => false
      },
      "owner" => %{
        "id" => 123456
      }
    }
  end

  def delete_repo_payload() do
    %{create_repo_payload() | "action" => "deleted"}
  end

  def rename_repo_payload() do
    %{create_repo_payload() | "action" => "renamed"}
    |> put_in(["repository", "name"], "new-name")
  end

  def privatize_repo_payload() do
    %{create_repo_payload() | "action" => "privatized"}
    |> put_in(["repository", "private"], true)
  end

  def publicize_repo_payload() do
    %{create_repo_payload() | "action" => "publicized"}
  end

  def push_commits_payload() do
    %{
      "commits" => [
        %{
          "id" => "a65d4f21df",
          "timestamp" => "2020-07-31T20:08:05-07:00",
          "message" => "commit message",
          "author" => %{
            "username" => "czynskee"
          },
          "distinct" => true
        },
        %{
          "id" => "dafdwerqa52",
          "timestamp" => "2020-07-31T20:08:05-07:00",
          "message" => "a second commit message",
          "author" => %{
            "username" => "czynskee"
          },
          "distinct" => true
        },
        %{
          "id" => "aer87qwe45234",
          "timestamp" => "2020-07-31T20:08:05-07:00",
          "message" => "a third commit message",
          "author" => %{
            "username" => "czynskee"
          },
          "distinct" => true
        },
      ],
      "repository" => %{
        "id" => 12345
      },
      "head_commit" => %{
        "added" => [],
        "modified" => [],
        "removed" => []
      },
      "ref" => "refs/head/master"
    }
  end

  def notes_commit_payload(opts) do
    map = %{
      "added" => [],
      "removed" => [],
      "modified" => []
    }

    map =
    if :added in opts do
      Map.put(map, "added", [
        "2020-08-01.md",
        "2020-07-31.md"
      ])
      else map
    end

    map =
    if :removed in opts do
      Map.put(map, "removed", [
        "2020-08-01.md",
        "2020-07-31.md"
      ])
      else map
    end

    map =
    if :modified in opts do
      Map.put(map, "modified", [
        "2020-08-01.md",
        "2020-07-31.md"
      ])
      else map
    end

    Map.put(push_commits_payload(), "head_commit", map)
  end

end
