defmodule GitNotes.TestHelpers do
  alias GitNotes.Accounts
  alias GitNotes.GitRepos

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

  def repo_fixture(attrs \\ %{}) do
    user = user_fixture()

    attrs
    |> Enum.into(%{
      "id" => 12345,
      "name" => "git_notes",
      "private" => true,
      "user_id" => user.id
    })
    |> GitRepos.create_repo()
    |> elem(1)
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
          "sha" => "a65d4f21df",
          "message" => "commit message",
          "author" => "czynskee",
          "distinct" => true
        },
        %{
          "sha" => "adfewrq510",
          "message" => "a second commit message",
          "author" => "czynskee",
          "distinct" => true
        },
        %{
          "sha" => "adqer1asf",
          "message" => "a third commit message",
          "author" => "czynskee",
          "distinct" => true
        },
      ],
      "repository" => %{
        "id" => 12345
      }
    }
  end

end
