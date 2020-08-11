defmodule GitNotesWeb.SessionControllerTest do
  use GitNotesWeb.ConnCase, async: true

  alias GitNotes.GithubAPI.Mock
  alias GitNotes.Accounts.User
  alias GitNotes.Accounts
  alias GitNotes.GitRepos

  import Mox
  setup :verify_on_exit!

  @oauth_url Application.fetch_env!(:git_notes, :oauth_url)
  @client_id Application.fetch_env!(:git_notes, :client_id)

  test "GET /new", %{conn: conn} do
    conn = conn
    |> get("/sessions/new")

    assert String.match?(conn.assigns.oauth_url, ~r/#{@oauth_url}\?client_id=#{@client_id}&state=.+/)
    assert html_response(conn, 200) =~ "#{@oauth_url}\?client_id=#{@client_id}&amp;state="

    link = URI.decode_query(conn.assigns.oauth_url)

    assert link["state"] == get_session(conn, :state)
  end

  test "GET /new oauth login state invalid", %{conn: conn} do
    conn
    |> get("/sessions/new")
    |> get("/sessions/new?code=1234&state=notthesamestate")
    |> assert_failed_login()

  end

  test "GET /new oauth login state is valid and we have already correctly
  installed app for user", %{conn: conn} do
    creds = github_oauth_credentials()
    Mock
    |> expect(:get_access_token, fn _code ->
      {:ok, creds}
    end)
    |> expect(:get_installations, fn _code ->
      {:ok,
        %{
          "total_count" => 1,
          "installations" =>
          [
            %{"id" => 123, "account" =>
              %{
                "login" => "czynskee",
                "id" => 12345
              }
            }
          ]
        }
      }
    end)

    user_fixture()

    conn = conn
    |> get("/sessions/new")

    conn = fetch_session(conn)
    |> get("/sessions/new?code=1234&state=#{get_session(conn, :state)}")

    assert %User{installation_id: 123} = user = Accounts.get_user_by(%{installation_id: 123})
    assert user.refresh_token == "r1.zxy987"
    assert user.access_token == "abc123"
    assert_in_delta user.refresh_token_expiration |> DateTime.to_unix(),
      now_plus_seconds(creds["refresh_token_expires_in"]), 5
    assert_in_delta user.access_token_expiration |> DateTime.to_unix(),
      now_plus_seconds(creds["expires_in"]), 5

    assert get_session(conn, :user_id) == user.id
    assert conn.assigns.current_user == user

    assert redirected_to(conn, 302) == "/"
    assert get_flash(conn, :info) == "Hello #{user.login}. You have logged in!"
  end

  test "sessions/new and subsequent api calls are successful but we have not
  already installed app for user", %{conn: conn} do
    creds = github_oauth_credentials()
    Mock
    |> expect(:get_access_token, fn _code ->
      {:ok, creds}
    end)
    |> expect(:get_installations, fn _code ->
      {:ok,
        %{
          "total_count" => 1,
          "installations" =>
          [
            %{"id" => 123, "account" =>
              %{
                "login" => "czynskee",
                "id" => 12345
              }
            }
          ]
        }
      }
    end)
    |> expect(:get_installation_access_token, fn _id ->
      installation_access_token_response()
    end)
    |> expect(:get_installation_repos, fn _token ->
      {:ok,
        %{ "repositories" => [
            %{
              "id" => 999,
              "name" => "coolrepo",
              "private" => true
            },
            %{
              "id" => 888,
              "name" => "othercoolrepo",
              "private" => false
            }
          ]
        }
      }
    end)

    assert Accounts.get_user_by(%{login: "czynskee"}) == nil

    conn = conn
    |> get("/sessions/new")

    conn = fetch_session(conn)
    |> get("/sessions/new?code=1234&state=#{get_session(conn, :state)}")

    assert %User{} = user = Accounts.get_user_by(%{login: "czynskee"})

    assert user.login == "czynskee"
    assert user.installation_id == 123
    assert user.id == 12345

    repos = GitRepos.list_user_repos(user)

    assert length(repos) == 2
    assert Enum.find(repos, & &1.name == "coolrepo" && &1.private == true && &1.id == 999 && &1.user_id == user.id)
    assert Enum.find(repos, & &1.name == "othercoolrepo" && &1.private == false && &1.id == 888 && &1.user_id == user.id)

    assert redirected_to(conn, 302) == "/"
    assert get_flash(conn, :info) == "Hello #{user.login}. You have logged in!"
  end

  test "sessions/new first api call to github goes wrong", %{conn: conn} do
    Mock
    |> expect(:get_access_token, fn _code ->
      :error
    end)

    conn = conn
    |> get("/sessions/new")

    fetch_session(conn)
    |> get("/sessions/new?code=1234&state=#{get_session(conn, :state)}")
    |> assert_failed_login()

  end

  test "sessions/new second api call to github fails", %{conn: conn} do
    Mock
    |> expect(:get_access_token, fn _code ->
      {:ok, github_oauth_credentials()}
    end)
    |> expect(:get_installations, fn _code ->
      :error
    end)

    conn = conn
    |> get("/sessions/new")

    fetch_session(conn)
    |> get("/sessions/new?code=1234&state=#{get_session(conn, :state)}")
    |> assert_failed_login()
  end

  test "sessions/new second api call to github goes wrong", %{conn: conn} do
    Mock
    |> expect(:get_access_token, fn _code ->
      {:ok, github_oauth_credentials()}
    end)
    |> expect(:get_installations, fn _code ->
      :error
    end)

    conn = conn
    |> get("/sessions/new")

    fetch_session(conn)
    |> get("/sessions/new?code=1234&state=#{get_session(conn, :state)}")
    |> assert_failed_login()
  end

  test "/sessions/new and the user has not installed the app yet", %{conn: conn} do
    Mock
    |> expect(:get_access_token, fn _code ->
      {:ok, %{
        "access_token" => "abc123",
        "expires_in" => "28800",
        "refresh_token" => "r1.zxy987",
        "refresh_token_expires_in" => "15811200",
        "scope" => "",
        "token_type" => "bearer"
      }}
    end)
    |> expect(:get_installations, fn _code ->
      {:ok, %{"total_count" => 0, "installations" => []}}
    end)

    conn = conn
    |> get("/sessions/new")

    conn = fetch_session(conn)
    |> get("/sessions/new?code=1234&state=#{get_session(conn, :state)}")

    assert redirected_to(conn, 303) =~ "/users/new"
    assert get_flash(conn, :info) == "You need to install the application before logging in."
  end


  test "login from installation" do
    # This would let people install and login in one step. Will not worry about implementing this for now.
  end

  test "/sessions/delete logs the user out", %{conn: conn} do
    conn = conn
    |> bypass_through(GitNotesWeb.Router, :browser)
    |> get("/")
    |> put_session(:user_id, 123)
    |> delete("/sessions/123")

    assert redirected_to(conn, 302) =~ "/"

    next_conn = get(conn, "/")
    refute get_session(next_conn, :user_id)
  end

  defp assert_failed_login(conn) do
    assert response(conn, 404)
    assert conn.halted
  end


end
