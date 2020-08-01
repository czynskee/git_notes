defmodule GitNotes.GithubTest do
  use GitNotes.DataCase, async: true

  alias GitNotes.GithubAPI.Mock
  alias GitNotes.Github
  alias GitNotes.Notes

  import Mox

  setup :verify_on_exit!

  test "get access token posts to github API" do
    expect(Mock, :get_access_token, fn _code ->
      {:ok, %{"access_code" => "123"}}
    end)

    Github.get_access_token("123")
  end

  test "get user posts to github API" do
    expect(Mock, :get_user, fn _token ->
      {:ok, %{"login" => "czynskee", "id" => 123456}}
    end)

    assert Github.get_user("123") == %{"login" => "czynskee", "id" => 123456}

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

    notes_repo = notes_repo_fixture(user, repo)

    Mock
    |> expect(:get_repo_contents, fn(_token, _user, _repo) ->
      [
        %{
          "name" => "2020-07-11.md"
        },
        %{
          "name" => "2020-07-12.md"
        }
      ]
    end)
    |> expect(:get_file_contents, fn(_token, _user, _repo, "2020-07-11.md") ->
      %{
        "name" => "2020-07-11.md",
        "content" => "aGVsbG8="
        }
    end)
    |> expect(:get_file_contents, fn(_token, _user, _repo, "2020-07-12.md") ->
      %{
        "name" => "2020-07-12.md",
        "content" => "Z29vZGJ5ZQ=="
        }
    end)
    |> expect(:get_installation_access_token, fn(_installation_id) ->
      "token"
    end)

    Github.populate_notes(notes_repo)

    notes = Notes.list_files_for_user(user.id)

    assert Enum.find(notes, &(&1.file_name == "2020-07-11.md"))
    assert Enum.find(notes, &(&1.file_name == "2020-07-12.md"))

  end


 end
