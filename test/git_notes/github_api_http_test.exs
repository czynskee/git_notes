defmodule GitNotes.GithubAPI.HTTPTest do
  use ExUnit.Case, async: true
  alias GitNotes.GithubAPI

  @api_url Application.fetch_env!(:git_notes, :github_api_url)
  @api_version Application.fetch_env!(:git_notes, :github_api_version)

  test "we correctly sub the github url" do
    assert GithubAPI.HTTP.process_request_url("") == @api_url
  end

  test "we add the jwt header automatically and the api version header unless they're provided" do
    default_headers = GithubAPI.HTTP.process_request_headers([])

    {_, token, _} = GitNotes.Token.get_jwt()

    assert Keyword.get(default_headers, :Authorization) == "Bearer #{token}"
    assert Keyword.get(default_headers, :Accept) == @api_version

    given_headers = GithubAPI.HTTP.process_request_headers([
      Authorization: "123",
      Accept: "456"
    ])

    assert Keyword.get(given_headers, :Authorization) == "123"
    assert Keyword.get(given_headers, :Accept) == "456"
    assert Keyword.get_values(given_headers, :Authorization) |> length == 1
    assert Keyword.get_values(given_headers, :Accept) |> length == 1
  end

  test "process response body handles errors" do
    assert {:error, reason} = GithubAPI.HTTP.process_response_body("balblablbalba")
  end

  test "process response body handles valid json" do
    assert {:ok, response} = GithubAPI.HTTP.process_response_body(~s({"age": 44, "name": "Steve Irwin"}))
    assert response == %{"age" => 44, "name" => "Steve Irwin"}
  end

end
