defmodule GitNotesWeb.WebhookControllerTest do
  use GitNotesWeb.ConnCase, async: true

  alias GitNotes.Accounts.User
  alias GitNotes.GitRepos.GitRepo
  alias GitNotes.Commits

  setup %{conn: conn} do
    conn = conn
      |> put_req_header("content-type", "application/json")

      {:ok, %{conn: conn}}
    end

  defp sign_request_and_post(conn, url, params) do
    {:ok, raw_body} = params |> Jason.encode()
    hash_signature = "sha1=#{GitNotesWeb.WebhookController.sign(raw_body)}"

    conn
    |> put_req_header("x-hub-signature", hash_signature)
    |> post(url, raw_body)
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

  test "deleted installation action removes user from database", %{conn: conn} do
    user_fixture()

    assert GitNotes.Accounts.get_user_by([installation_id: 123]) != nil

    params = delete_installation_payload()

    conn = conn
    |> sign_request_and_post("/webhooks", params)

    assert GitNotes.Accounts.get_user_by([installation_id: 123]) == nil
    assert response(conn, 200)
  end

  test "created installation action adds user and repos to database", %{conn: conn} do
    params = create_installation_payload()

    conn = conn
    |> sign_request_and_post("/webhooks", params)

    assert %User{id: 123456} = user = GitNotes.Accounts.get_user(123456)

    repos = GitNotes.GitRepos.list_user_repos(user)
    assert Enum.find(repos, fn repo -> repo.id === 12345 end)
    assert Enum.find(repos, fn repo -> repo.id === 678910 end)
    assert response(conn, 200)
  end

  test "created repo action adds repo to the database under correct user", %{conn: conn} do
    user = user_fixture()

    params = create_repo_payload()

    sign_request_and_post(conn, "/webhooks", params)

    assert repo = GitNotes.GitRepos.get_repo(get_in(params, ["repository", "id"]))
    assert repo.user_id == user.id
    assert repo.name == "new-repo"
    assert repo.private == false
  end

  test "deleted repo action deletes repo from database under correct user", %{conn: conn} do
    repo = repo_fixture()

    assert %GitRepo{} = GitNotes.GitRepos.get_repo(repo.id)

    sign_request_and_post(conn, "/webhooks", delete_repo_payload())

    assert GitNotes.GitRepos.get_repo(repo.id) == nil
  end

  test "renamed repo action renames repo", %{conn: conn} do
    repo = repo_fixture()

    sign_request_and_post(conn, "/webhooks", rename_repo_payload())

    assert GitNotes.GitRepos.get_repo(repo.id).name == get_in(rename_repo_payload(), ["repository", "name"])
  end

  test "privatized action privatizes repo", %{conn: conn} do
    repo = repo_fixture(%{"private" => false})
    assert repo.private == false

    sign_request_and_post(conn, "/webhooks", privatize_repo_payload())

    assert GitNotes.GitRepos.get_repo(repo.id).private == true
  end

  test "publicize action publicizes repo", %{conn: conn} do
    repo = repo_fixture()
    assert repo.private == true

    sign_request_and_post(conn, "/webhooks", publicize_repo_payload())

    assert GitNotes.GitRepos.get_repo(repo.id).private == false
  end

  test "new push adds commits to appropriate repo", %{conn: conn} do
    repo = repo_fixture()

    sign_request_and_post(conn, "/webhooks", push_commits_payload())

    commits = Commits.list_commits_by_repo(repo)

    assert length(commits) === 3
    assert Enum.find(commits, &(&1.message == "commit message"))
    assert Enum.find(commits, &(&1.message == "a second commit message"))
    assert Enum.find(commits, &(&1.message == "a third commit message"))
  end



end
