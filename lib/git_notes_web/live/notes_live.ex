defmodule GitNotesWeb.NotesLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias GitNotes.{Accounts, Notes, Github}

  def render(assigns) do
    GitNotesWeb.NotesView.render("notes_live.html", assigns)
  end

  def mount(_params, session, socket) do
    GitNotesWeb.Endpoint.subscribe("user: #{session["user_id"]}")
    date_range = Date.range(Date.add(Date.utc_today(), -2), Date.add(Date.utc_today(), -2))
    |> Enum.to_list()

    socket = socket
    |> assign(
      user: Accounts.get_user(session["user_id"]),
      date_range: date_range,
      current_date: List.first(date_range))
    |> get_topic_info()

    {:ok, socket}
  end

  defp get_topic_info(socket) do
    topics = Notes.list_user_topics_with_entries(socket.assigns.user.id)

    socket
    |>assign(:topics, topics)
  end

  def handle_info(%{event: "new_commits", payload: %{"commits" => commits}}, socket) do
    for commit <- commits do
      send_update GitNotesWeb.DayComponent, id: commit.commit_date, date: commit.commit_date, user: socket.assigns.user
    end
    {:noreply, socket}
  end

  def handle_info(%{event: "file_change", payload: %{"files" => files}}, socket) do
    for file <- files do
      send_update GitNotesWeb.DayComponent, id: file.file_name_date, date: file.file_name_date, user: socket.assigns.user
    end
    {:noreply, socket}
  end

  def handle_event("change_range", %{"direction" => direction}, socket) do
    amount = if direction == "back", do: -1, else: 1
    socket = assign(socket, :date_range, Enum.map(socket.assigns.date_range, & Date.add(&1, amount)))
    {:noreply, socket}
  end

  def handle_event("current_date", %{"date" => date_string}, socket) do
    {:noreply, assign(socket, :current_date, Date.from_iso8601!(date_string))}
  end
end
