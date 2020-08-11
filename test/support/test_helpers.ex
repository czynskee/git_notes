defmodule GitNotes.TestHelpers do
  alias GitNotes.Accounts
  alias GitNotes.GitRepos

  @app_id Application.fetch_env!(:git_notes, :github_app_id)

  def user_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      "installation_id" => 123,
      "id" => 123456,
      "login" => "czynskee"
    })
    |> Accounts.register_user()
  end

  def repo_fixture(attrs \\ %{}) do
    attrs
    |> Enum.into(%{
      "id" => 12345,
      "name" => "git_notes",
      "private" => true,
      "user_id" => 123456
    })
    |> GitRepos.create_repo()
  end


  def fixtures() do
    user = user_fixture()
    repo = repo_fixture(%{"user_id" => user.id})

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

  def github_oauth_credentials() do
    %{
      "access_token" => "abc123",
      "expires_in" => "28800",
      "refresh_token" => "r1.zxy987",
      "refresh_token_expires_in" => "15811200",
      "scope" => "",
      "token_type" => "bearer"
    }
  end

  def now_plus_seconds(seconds) do
    DateTime.now("Etc/UTC")
    |> elem(1)
    |> DateTime.add(seconds
      |> Integer.parse()
      |> elem(0))
    |> DateTime.to_unix()
  end

  def installation_access_token_response() do
    {:ok, %{
      "token" => "heresatoken",
      "expires_at" => "2016-07-11T22:14:10Z"
    }}
  end

end
