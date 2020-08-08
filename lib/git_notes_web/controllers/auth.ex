defmodule GitNotesWeb.Auth do
  import Phoenix.Controller
  import Plug.Conn
  alias GitNotesWeb.Router.Helpers, as: Routes
  alias GitNotes.{Accounts, GitRepos, Github}

  @oauth_url Application.fetch_env!(:git_notes, :oauth_url)
  @client_id Application.fetch_env!(:git_notes, :client_id)

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    cond do
      user = user_id && Accounts.get_user(user_id) ->
        put_current_user(conn, user)
      true ->
        conn
        |> assign(:current_user, nil)
    end
  end

  def put_oauth_url(conn) do
    state = get_state()
    conn
    |> assign(:oauth_url, oauth_url(state))
    |> put_session(:state, state)
    |> configure_session(renew: true)
  end

  def oauth_login(conn, code, state) do
    oauth_login(conn, code, state, get_session(conn, :state))
  end

  defp oauth_login(conn, code, state, session_state) when state == session_state do
    case Github.get_access_token(code) do
      {:ok, credentials} ->
        case Github.get_installations(credentials["access_token"]) do
          {:ok, installations} ->
            login(conn, credentials, installations)
          :error -> failed_login(conn)
        end
      :error -> failed_login(conn)
    end
  end

  defp oauth_login(conn, _code, state, session_state) when state != session_state do
    failed_login(conn)
  end

  defp login(conn, _credentials, %{"total_count" => total_count}) when total_count < 1 do
    conn
      |> put_flash(:info, "You need to install the application before logging in.")
      |> put_status(303)
      |> redirect(to: Routes.user_path(conn, :new))
  end

  defp login(conn, credentials, installations) do
      installation = Enum.at(installations["installations"], 0)

      user = case Accounts.get_user_by(%{installation_id: installation["id"]}) do
        nil ->
          user = Accounts.register_user(%{
            "login" => get_in(installation, ["account", "login"]),
            "id" => get_in(installation, ["account", "id"]),
            "installation_id" => get_in(installation, ["id"])
          })

          # Task.async(fn ->
            case Github.get_installation_repos(user.installation_id) do
              {:ok, response} ->
                GitRepos.create_repos_for_user(user, response)
              :error -> IO.puts "There was an error getting the repos for an installed
              user. These should be put into some kind of log to be retried"
            end
          # end)
          user
        user -> user
      end
      |> Accounts.update_github_credentials(credentials)

      conn
      |> put_current_user(user)
      |> put_session(:user_id, user.id)
      |> configure_session(renew: true)
      |> put_flash(:info, "Hello #{user.login}. You have logged in!")
      |> redirect(to: Routes.page_path(conn, :index))
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end

  defp put_current_user(conn, user) do
    conn
    |> assign(:current_user, user)
  end

  defp failed_login(conn) do
    conn
    |> halt()
    |> send_resp(404, "")
  end

  defp oauth_url(state) do
    "#{@oauth_url}?client_id=#{@client_id}&state=#{state}"
  end

  defp get_state() do
    :crypto.strong_rand_bytes(64) |> Base.url_encode64()
  end

  def authenticate(conn, _opts \\ %{}) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access that resource")
      |> redirect(to: Routes.session_path(conn, :new))
      |> halt()
    end
  end

end
