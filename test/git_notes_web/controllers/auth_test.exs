defmodule GitNotesWeb.AuthTest do
  use GitNotesWeb.ConnCase, async: true

  alias GitNotesWeb.Auth

  setup %{conn: conn} do
    conn = conn
    |> bypass_through(GitNotesWeb.Router, :browser)
    |> get("/")

    {:ok, %{conn: conn}}
  end

  test "authenticate user halts request when the current user is not assigned", %{conn: conn} do
    conn = Auth.authenticate(conn)

    assert conn.halted
    assert redirected_to(conn, 302) == "/sessions/new"
    assert get_flash(conn, :error) == "You must be logged in to access that resource"
  end

  test "authenticate user continues when the current_user is assigned", %{conn: conn} do
    conn = conn
    |> assign(:current_user, %GitNotes.Accounts.User{})
    |> Auth.authenticate()

    refute conn.halted
  end

  test "logout drops the session", %{conn: conn} do
    logout_conn = conn
    |> put_session(:user_id, 123)
    |> Auth.logout()
    |> send_resp(:ok, "")

    next_conn = get(logout_conn, "/")
    refute get_session(next_conn, :user_id)
  end

end
