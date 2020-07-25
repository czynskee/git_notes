defmodule GitNotes.GithubTest do
  use ExUnit.Case, async: true
  alias GitNotes.Github


  import Mox

  test "get user token posts to github API" do
    assert Github.get_access_token("code") == %{"access_token" => "token"}
  end

 end
