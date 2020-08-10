defmodule GitNotesWeb.NotesLive do
  use Phoenix.LiveView
  alias GitNotes.{Accounts, Notes, Commits}

  def render(assigns) do
    ~L"""
    <div>
      <%= @file.name %>
    </div>
    <textarea id="notes-textarea" phx-hook="NotesHook" data-content="<%= @file.content %>" > </textarea>
    <%= for commit <- @commits do %>
      <div>
        <%= commit.message %>
      </div>

    <% end %>

    """
  end

  def mount(params, session, socket) do
    user_id = session["user_id"]
    date = DateTime.now("Etc/UTC") |> elem(1)
    current_file = Notes.get_file_by_date(user_id, date)
    days_commits = Commits.get_commits_by_date(user_id, date)

    IO.inspect days_commits

    socket = socket
    |> assign(:user, Accounts.get_user(user_id))
    |> assign(:file, current_file)
    |> assign(:commits, days_commits)
    {:ok, assign(socket, :file, current_file)}
  end
end
