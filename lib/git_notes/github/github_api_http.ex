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

  def get_installation_access_token(installation_id) do
    post("/app/installations/#{installation_id}/access_tokens", "")
    |> get_response()
  end

  def get_user(token) do
    get("/user", user_token(token))
    |> get_response()
  end

  def get_installation_repos(token) do
    get("/installation/repositories", user_token(token))
    |> get_response()
  end

  def get_installations(token) do
    get("/user/installations", user_token(token))
    |> get_response()
  end

  def get_repo_contents(token, user, repo) do
    get("#{repo_path(user, repo)}/contents/", user_token(token))
    |> get_response()
  end


  def get_repo_commits(token, user, repo) do
    get("#{repo_path(user, repo)}/commits", user_token(token))
    |> get_response()
  end

  def get_file_contents(token, user, repo, filename) do
    get("#{repo_path(user, repo)}/contents/#{filename}", user_token(token))
    |> get_response()
  end

  def refresh_access_token(user) do
    case @http_adapter.post("https://github.com/login/oauth/access_token?refresh_token=#{user.refresh_token}&grant_type=refresh_token&client_id=#{@client_id}&client_secret=#{@client_secret}",
    ""
    ) do
      {:error, _} -> :error
      {:ok, response} -> {:ok, URI.decode_query(response.body)}
    end
  end

  def get_repo_master_head(token, user, repo) do
    get("#{repo_path(user, repo)}/git/ref/heads/master", user_token(token))
    |> get_response()
  end

  def get_commit(token, user, repo, sha) do
    get("#{repo_path(user, repo)}/git/commits/#{sha}", user_token(token))
    |> get_response()
  end

  def post_blob(token, user, repo, blob_content) do
    content = Jason.encode(%{content: blob_content}) |> elem(1)

    post("#{repo_path(user, repo)}/git/blobs", content, user_token(token))
    |> get_response()
  end

  def get_tree(token, user, repo, sha) do
    get("#{repo_path(user, repo)}/git/trees/#{sha}", user_token(token))
    |> get_response()
  end

  def post_tree(token, user, repo, tree) do
    tree = Jason.encode(tree) |> elem(1)
    post("#{repo_path(user, repo)}/git/trees", tree, user_token(token))
    |> get_response()
  end

  def post_commit(token, user, repo, commit) do
    commit = Jason.encode(commit) |> elem(1)
    post("#{repo_path(user, repo)}/git/commits", commit, user_token(token))
    |> get_response()
  end


  def patch_master_head_commit_reference(token, user, repo, commit_sha) do
    payload = %{sha: commit_sha} |> Jason.encode() |> elem(1)

    patch("#{repo_path(user, repo)}/git/refs/heads/master", payload, user_token(token))
    |> get_response()
  end

  defp get_response({:error, _reason}), do: :error
  defp get_response({:ok, %{body: %{"message" => "Bad credentials"}}}), do: :error
  defp get_response({:ok, response}), do: response.body

  defp repo_path(user, repo), do: "/repos/#{user.login}/#{repo.name}"

  defp user_token(token) do
    [Authorization: "token #{token}"]
  end




end
