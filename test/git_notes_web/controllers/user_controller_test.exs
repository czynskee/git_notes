defmodule GitNotesWeb.UserControllerTest do
  use GitNotesWeb.ConnCase, async: true

  @app_name Application.fetch_env!(:git_notes, :public_app_name)


  # alias GitNotes.GithubAPI.Mock
  # import Mox

  # setup :verify_on_exit!

  test "GET /users/new", %{conn: conn} do
    conn = get(conn, "/users/new")
    assert html_response(conn, 200) =~ "https://github.com/apps/#{@app_name}/installations/new"
  end

  # test "GET /users/install with proper params", %{conn: conn} do
  #   Mock
  #     |> expect(:get_access_token, fn _code ->
  #       {:ok, %{
  #         "access_token" => "12345",
  #         "expires_in" => "28800",
  #         "refresh_token" => "r1.2345645",
  #         "refresh_token_expires_in" => "15897600",
  #         "scope" => "",
  #         "token_type" => "bearer"
  #       }
  #     }
  #     end)
  #     |> expect(:get_user, fn _token ->
  #       {:ok, %{"login" => "czynskee", "id" => 123456}}
  #     end)

  #   get(conn, "/users/install", %{"code" => "123", "installation_id" => "456", "setup_action" => "install" })

  #   user = GitNotes.Accounts.get_user(123456)

  #   assert user.id == 123456
  #   assert user.installation_id == 456
  #   assert user.login == "czynskee"

  #   # log user in and redirect to "/"
  # end

  # test "GET /users/install with no params", %{conn: conn} do
  #   conn = get(conn, "users/install", %{})

  #   assert redirected_to(conn) == "/"
  # end
end
