defmodule GitNotes.TokenTest do
  use ExUnit.Case, async: false

  alias GitNotes.Token

  describe "testing JWTs" do
    Token.start_link()

    setup do
      Token.set_key("exp", nil)
      Token.set_key("jwt", nil)
      :ok
    end

    test "Test generate and sign creates a jwt with the right claims" do

      {:ok, _token, claims} = Token.get_jwt()

      assert claims["iss"] == Application.fetch_env!(:git_notes, :github_app_id)
      assert claims["iat"]
      assert claims["exp"]
    end

    test "Assert that the jwt we generate decodes to one with the right alg and iss" do
      {:ok, token, _claims } = Token.get_jwt()

      {:ok, claims} = Token.verify_and_validate(token)

      assert claims["iss"] == Application.fetch_env!(:git_notes, :github_app_id)

      {:ok, header} = Joken.peek_header(token)

      assert header["alg"] == "RS256"
      assert header["typ"] == "JWT"
    end

    test "generate and signing a jwt should only create a new jwt if the old one is expired" do
      {:ok, token1, _claims} = Token.get_jwt()
      {:ok, token2, _claims} = Token.get_jwt()

      assert token1 == token2
    end

    test "generate and signing a jwt should create a new jwt after 10 minutes" do
      iat = DateTime.now("Etc/UTC") |> elem(1) |> DateTime.to_unix()

      iat = iat - 5000
      exp = iat + 600

      {:ok, old_token, _claims} = Token.get_jwt(%{"iat" => iat, "exp" => exp})

      {:ok, token, _claims} = Token.get_jwt()

      assert token != old_token
    end

  end
end
