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

 end
