defmodule GitNotesWeb.SessionControllerTest do
  use GitNotesWeb.ConnCase, async: true

  @oauth_url Application.fetch_env!(:git_notes, :oauth_url)
  @client_id Application.fetch_env!(:git_notes, :client_id)

  test "GET /new", %{conn: conn} do
    conn = conn
    |> get("/sessions/new")

    assert String.match?(conn.assigns.oauth_url, ~r/#{@oauth_url}\?client_id=#{@client_id}&state=.+/)
  end

end
