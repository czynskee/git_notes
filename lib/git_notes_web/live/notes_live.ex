defmodule GitNotesWeb.NotesLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias GitNotes.{Accounts, Notes, Commits, Github}

  def render(assigns) do
    GitNotesWeb.NotesView.render("notes_live.html", assigns)
  end

  def mount(_params, session, socket) do
    GitNotesWeb.Endpoint.subscribe("user#{session["user_id"]}")

    socket = socket
    |> assign(:user_id, session["user_id"])
    |> assign(:file_changeset, Notes.change_file(%Notes.File{}))

    {:ok, get_days_info(socket, Date.utc_today())}
  end

  def handle_info(%{"event" => "new_commits"} = event, socket) do
    IO.inspect event
    {:noreply, get_commit_info(socket)}
  end

  def handle_event("commit_notes", _value, %{assigns: %{editing: false}} = socket) do
    socket = socket
    |> assign(:editing, true)

    {:reply, %{}, socket}
  end

  def handle_event("commit_notes", %{"file" => %{"content" => content}}, socket) do
    Github.commit_and_push_file(socket.assigns, content)
    socket = socket
    |> assign(:editing, false)

    {:reply, %{}, socket}
  end


  def handle_event("previous_day", _value, socket) do
    previous_date = Date.add(socket.assigns.date, -1)

    {:reply, %{}, get_days_info(socket, previous_date)}
  end

  def handle_event("next_day", _value, socket) do
    next_date = Date.add(socket.assigns.date, 1)

    {:reply, %{}, get_days_info(socket, next_date)}
  end


  defp get_days_info(socket, date) do
    user_id = socket.assigns.user_id
    current_file = Notes.get_file_by_date(user_id, date)

    socket
    |> assign(:date, date)
    |> assign(:editing, false)
    |> assign(:user, Accounts.get_user(user_id))
    |> assign(:file, current_file)
    |> get_commit_info
  end

  defp get_commit_info(socket) do
    days_commits = Commits.get_commits_by_date(socket.assigns.user.id, socket.assigns.date)

    socket
    |> assign(:commits, days_commits)
  end
end
