defmodule GitNotesWeb.SessionController do
  use GitNotesWeb, :controller
  alias GitNotesWeb.Auth

  def new(conn, %{"code" => code, "state" => state}) do
    conn
    |> Auth.oauth_login(code, state)
  end

  def new(conn, _params) do
    conn
    |> Auth.put_oauth_url()
    |> render("new.html")
  end

  def delete(conn, _params) do
    conn
    |> Auth.logout()
    |> redirect(to: Routes.page_path(conn, :index))
  end



end
