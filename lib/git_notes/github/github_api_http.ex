defmodule GitNotes.GithubAPI.HTTP do
  @behaviour GitNotes.GithubAPI
  @api_url Application.fetch_env!(:git_notes, :github_api_url)
  @api_version Application.fetch_env!(:git_notes, :github_api_version)
  @http_adapter Application.fetch_env!(:git_notes, :http_adapter)
  @client_id Application.fetch_env!(:git_notes, :client_id)
  @client_secret Application.fetch_env!(:git_notes, :client_secret)

  alias GitNotes.Token
  use HTTPoison.Base

  def process_request_url(url) do
    @api_url <> url
  end

  def process_request_headers(headers) do
    headers
      |> Keyword.put_new_lazy(:Authorization, fn ->
        {:ok, token, _} = Token.get_jwt()
        "Bearer #{token}"
      end)
      |> Keyword.put_new(:Accept, @api_version)
    end

  def process_response_body("") do
    ""
  end

  def process_response_body(body) do
    Jason.decode(body)
  end


  def get_access_token(code) do
    case @http_adapter.post(
      "https://github.com/login/oauth/access_token?client_id=#{@client_id}&client_secret=#{@client_secret}&code=#{code}",
      ""
      ) do
        {:error, _} -> :error
        {:ok, response} -> {:ok, URI.decode_query(response.body)}
      end
  end

  def get_username(token) do
    case get("/user", [Authorization: "token #{token}"]) do
        {:error, _} -> :error
        {:ok, response} -> response.body
    end
  end

end
