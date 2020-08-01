defmodule GitNotesWeb.WebhookController do
  use GitNotesWeb, :controller
  alias GitNotes.Accounts
  alias GitNotes.GitRepos

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
    :crypto.hmac(:sha, @webhook_secret, raw_body) |> Base.encode16 |> String.downcase()
  end

  def webhook(conn, %{"action" => "created",
  "installation" => %{"id" => installation_id, "app_id" => @app_id}} = payload) do
    user =
    get_in(payload, ["installation", "account"])
    |> Map.put("installation_id", installation_id)

    Accounts.register_user(user)

    get_in(payload, ["repositories"])
    |> Enum.each(fn repo ->
      repo
      |> Map.put("user_id", user["id"])
      |> GitRepos.create_repo()
    end)

    send_resp(conn, 200, "")
  end

  def webhook(conn, %{"action" => "deleted", "installation" => %{"id" => installation_id, "app_id" => @app_id}}) do
    Accounts.get_user_by([installation_id: installation_id])
    |> Accounts.delete_user()

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

  def webhook(conn, _params) do
    send_resp(conn, 200, "")
  end


end
