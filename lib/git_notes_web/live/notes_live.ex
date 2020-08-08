defmodule GitNotesWeb.NotesLive do
  use Phoenix.LiveView
  alias GitNotes.{Accounts, Notes, Commits}

  def render(assigns) do
    ~L"""
    Hello! <%= @user.login %>
    """
  end

  def mount(params, session, socket) do
    user_id = session["user_id"]
    IO.inspect Notes.list_user_files(user_id)
    IO.inspect Commits.list_user_commits(user_id)

    socket = socket
    |> assign(:user, Accounts.get_user(user_id))
    {:ok, assign(socket, :message, "a message")}
  end
end
