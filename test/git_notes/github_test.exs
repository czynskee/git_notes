defmodule GitNotes.GithubTest do
  use GitNotes.DataCase, async: true

  alias GitNotes.GithubAPI.Mock
  alias GitNotes.Github
  alias GitNotes.Notes

  import Mox

  setup :verify_on_exit!

  test "get access token posts to github API" do
    expect(Mock, :get_access_token, fn _code ->
      {:ok, %{"access_token" => "123"}}
    end)

    Github.get_access_token("123")
  end

  test "get user posts to github API" do
    expect(Mock, :get_user, fn _token ->
      {:ok, %{"login" => "czynskee", "id" => 123456}}
    end)

    assert Github.get_user("123") == {:ok, %{"login" => "czynskee", "id" => 123456}}

  end

  test "get installation access token" do
    Mock
      |> expect(:get_installation_access_token, fn(_installation_id) ->
        {:ok, %{"token" => 12345, "expires_at" => (DateTime.now("Etc/UTC") |> elem(1) |> DateTime.add(60 * 60))}}
      end)

    Github.get_installation_access_token(12345)
  end

  test "populate notes" do
    %{user: user, repo: repo} = fixtures()

    GitNotes.Accounts.update_user(user, %{"notes_repo_id" => repo.id})

    Mock
    |> expect(:get_repo_contents, fn(_token, _user, _repo) ->
      {:ok, [
        %{
          "name" => "2020-07-11.md"
        },
        %{
          "name" => "2020-07-12.md"
        }
      ]
    }
    end)
    |> expect(:get_file_contents, fn(_token, _user, _repo, "2020-07-11.md") ->
      {:ok, %{
        "name" => "2020-07-11.md",
        "content" => "aGVsbG8="
        }
      }
    end)
    |> expect(:get_file_contents, fn(_token, _user, _repo, "2020-07-12.md") ->
      {:ok, %{
        "name" => "2020-07-12.md",
        "content" => "Z29vZGJ5ZQ=="
        }
      }
    end)
    |> expect(:get_installation_access_token, fn(_installation_id) ->
      {:ok, %{
        "token" => "heresatoken"
      }}
    end)

    Github.populate_notes(repo.id)
    notes = Notes.list_user_files(user.id)


    assert Enum.find(notes, &(&1.name == "2020-07-11.md"))
    assert Enum.find(notes, &(&1.name == "2020-07-12.md"))

  end


 end
