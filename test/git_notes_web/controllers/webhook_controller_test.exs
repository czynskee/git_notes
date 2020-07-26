defmodule GitNotesWeb.WebhookControllerTest do
  use GitNotesWeb.ConnCase, async: true

  @app_id Application.fetch_env!(:git_notes, :github_app_id)

  setup %{conn: conn} do
    conn = conn
      |> put_req_header("content-type", "application/json")

    {:ok, %{conn: conn}}
  end

  test "verify_signature returns 403 and halts if signatures don't match", %{conn: conn} do
    {:ok, params} = %{"bad_action" => "destroy"} |> Jason.encode()
    conn = conn
      |> put_req_header("x-hub-signature", "a trick")
      |> post("/webhooks", params)

    assert response(conn, 403)
    assert conn.halted
  end

  test "verify_signature allows conn through if signatures match", %{conn: conn} do
      conn = conn
      |> sign_request_and_post("/webhooks", %{"good_action" => "yay"})

      assert response(conn, 200)
  end

  test "deleted action removes user from database", %{conn: conn} do
    user_fixture()

    assert GitNotes.Accounts.get_user_by([installation_id: "123"]) != nil

    params = %{"action" => "deleted", "installation" => %{"id" => "123", "app_id" => @app_id}}

    conn = conn
    |> sign_request_and_post("/webhooks", params)

    assert GitNotes.Accounts.get_user_by([installation_id: "123"]) == nil
    assert response(conn, 200)
  end

  defp sign_request_and_post(conn, url, params) do
    {:ok, raw_body} = params |> Jason.encode()
    hash_signature = "sha1=#{GitNotesWeb.WebhookController.sign(raw_body)}"

    conn
      |> put_req_header("x-hub-signature", hash_signature)
      |> post(url, raw_body)
  end

end
