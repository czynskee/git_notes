defmodule GitNotesWeb.SessionController do
  use GitNotesWeb, :controller
  alias GitNotesWeb.Auth

  def new(conn, _params) do
    conn
    |> Auth.put_oauth_url()
    |> render("new.html")
  end



end
