defmodule GitNotesWeb.PageControllerTest do
  use GitNotesWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Phoenix!"
  end
end
