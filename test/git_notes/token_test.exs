defmodule GitNotes.TokenTest do
  use GitNotes.DataCase, async: true

  alias GitNotes.Token

  setup do
    Token.start_link()
    on_exit(fn() -> Token.stop() end)
    :ok
  end

  test "Test generate and sign creates a token with the right claims" do

    {:ok, _token, claims} = Token.get_token()

    assert claims["iss"] == Application.fetch_env!(:git_notes, :github_app_id)
    assert claims["iat"]
    assert claims["exp"]
  end

  test "Assert that the token we generate decodes to one with the right alg and iss" do
    {:ok, token, _claims } = Token.get_token()

    {:ok, claims} = Token.verify_and_validate(token)

    assert claims["iss"] == Application.fetch_env!(:git_notes, :github_app_id)

    {:ok, header} = Joken.peek_header(token)

    assert header["alg"] == "RS256"
    assert header["typ"] == "JWT"
  end

  test "generate and signing a token should only create a new token if the old one is expired" do
    {:ok, token1, _claims} = Token.get_token()
    :timer.sleep(1000)

    {:ok, token2, _claims} = Token.get_token()

    assert token1 == token2
  end

  test "generate and signing a token should create a new token after 10 minutes" do
    iat = DateTime.now("Etc/UTC") |> elem(1) |> DateTime.to_unix()

    iat = iat - 1000
    exp = iat + 600

    {:ok, old_token, _claims} = Token.get_token(%{"iat" => iat, "exp" => exp})

    {:ok, token, _claims} = Token.get_token()

    assert token != old_token
  end



end
