defmodule GitNotesWeb.WebhookController do
  use GitNotesWeb, :controller
  alias GitNotes.Accounts
  alias GitNotes.GitRepos
  alias GitNotes.Commits
  alias GitNotes.Github

  @webhook_secret Application.fetch_env!(:git_notes, :webhook_secret)
  @app_id Application.fetch_env!(:git_notes, :github_app_id)

  def verify_signature(conn, _params) do
    signature = sign(conn.assigns.raw_body)
    request_signature = get_req_header(conn, "x-hub-signature") |> Enum.at(0)
    if "sha1=#{signature}" == request_signature do
      conn
    else
      conn
      |> send_resp(403, "signatures did not match")
      |> halt
    end
  end

  def sign(raw_body) do
    :crypto.hmac(:sha, @webhook_secret, raw_body)
    |> Base.encode16
    |> String.downcase()
  end

  def webhook(conn, %{"action" => "created",
  "installation" => %{"id" => installation_id, "app_id" => @app_id}} = payload) do
    user =
    get_in(payload, ["installation", "account"])
    |> Map.put("installation_id", installation_id)

    user = Accounts.register_user(user)

    GitRepos.create_repos_for_user(user, payload)

    Github.populate_commits(user)

    send_resp(conn, 200, "")
  end

  def webhook(conn,
    %{"action" => "deleted", "installation" => %{"id" => installation_id, "account" => %{"login" => login}, "app_id" => @app_id}}) do
    user = Accounts.get_user_by([installation_id: installation_id])
    user = user || Accounts.get_user_by([login: login])

    if user do
      Accounts.delete_user(user)
    end

    send_resp(conn, 200, "")
  end

  def webhook(conn, %{"action" => "created", "repository" => repository, "owner" => %{"id" => id}}) do
    repository
    |> Map.put("user_id", id)
    |> GitRepos.create_repo()

    send_resp(conn, 200, "")
  end

  def webhook(conn, %{"action" => "deleted", "repository" => %{"id" => id}}) do
    GitRepos.delete_repo(id)
    send_resp(conn, 200, "")
  end

  def webhook(conn, %{"action" => action, "repository" => repository})
  when action in ["renamed", "privatized", "publicized"] do
    GitRepos.update_repo(repository)
    send_resp(conn, 200, "")
  end

  def webhook(conn, %{"commits" => commits, "ref" => ref, "repository" => %{"id" => repo_id}} = payload) do
    commits
    |> Enum.map(&(Map.put(&1, "git_repo_id", repo_id)))
    |> Enum.map(&(Map.put(&1, "author", get_in(&1, ["author", "username"]))))
    |> Enum.map(&(Map.put(&1, "commit_date",
      &1["timestamp"]
      |> String.split("T") |> Enum.at(0) |> Date.from_iso8601() |> elem(1))))
    |> Enum.map(&(Map.put(&1, "sha", &1["id"])))
    |> Enum.map(&(Map.put(&1, "ref", ref)))
    |> Enum.each(&(Commits.create_commit(&1)))

    repo = GitRepos.get_repo(repo_id)
    GitNotesWeb.Endpoint.broadcast("user: #{repo.user_id}", "new_commits", %{})

    user = Accounts.get_user_and_notes_repo(repo_id)

    if user do
      Github.update_notes_files(user, payload["head_commit"])
      GitNotesWeb.Endpoint.broadcast("user: #{repo.user_id}", "updated_file", %{})
    end

    send_resp(conn, 200, "")
  end

  def webhook(conn, _params) do
    send_resp(conn, 404, "")
  end

end
