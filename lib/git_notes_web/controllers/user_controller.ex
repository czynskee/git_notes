defmodule GitNotesWeb.UserController do
  use GitNotesWeb, :controller

  alias GitNotes.Github

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def install(conn, %{"code" => code, "installation_id" => installation_id, "setup_action" => "install"}) do
    case GitNotes.Github.get_access_token(code) do
      :error ->
        install_error(conn)
      {:ok, %{"error" => _error}} ->
        install_error(conn)
      {:ok, response} ->
        user = Github.get_user(response["access_token"])
        refresh_expiration =
          DateTime.now("Etc/UTC")
          |> elem(1)
          |> DateTime.add(
          response["refresh_token_expires_in"] |> Integer.parse() |> elem(0))

        case GitNotes.Accounts.register_user(%{
          login: user["login"],
          id: user["id"],
          installation_id: installation_id,
          refresh_token: response["refresh_token"],
          refresh_token_expiration: refresh_expiration
        }) do
          {:error, _} -> install_error(conn)
          {:ok, _user} ->
            conn
              |> put_flash(:info, "Successful installation")
              |> redirect(to: "/")
        end
    end
  end

  def install(conn, _params) do
    conn
    |> redirect(to: "/")
  end

  def install_error(conn) do
    conn
    |> put_flash(:error, "There was an error processing your request. Please try again.")
    |> redirect(to: "/")
  end
end
