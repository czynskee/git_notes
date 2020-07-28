defmodule GitNotes.GithubTest do
  use ExUnit.Case, async: true

  alias GitNotes.GithubAPI.Mock
  alias GitNotes.Github

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
        {:ok, %{"token" => 12345, "expires_at" => DateTime.now("Etc/UTC")}}
      end)

      Github.get_installation_access_token(12345)
  end

  test "given an installation id registers a new user account" do
    Mock
      |>

    assert {:ok, %User{} = user} = Github.new_installation(12345)

    # check to make sure that they're correctly added to the database
    # check to make sure their repos are correctly added to the database
  end

  test "given an installation id and an oauth token, register a new user account" do
    Mock
      |>

    assert {:ok, %User{} = user} = Github.new_installation(12345, 678910)

    # check to make sure that they're correctly added to the database
    # check to make sure their repos are correctly added to the database
  end

  test "given an installation id, we handle subsequent network errors gracefully" do
    Mock
      |>

    assert {:error, reason} = Github.new_installation(12345)
    # assert reason ==

    # check to make sure they're not added to the database
    # check to make sure their repos are not added to the database
  end

 end
