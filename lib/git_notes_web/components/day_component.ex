defmodule GitNotesWeb.DayComponent do
  use GitNotesWeb, :live_component

  alias GitNotes.{Notes, Commits, Github}


  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = socket
    |> Map.put(:assigns, Map.merge(socket.assigns, assigns))
    |> assign(:file_changeset, Notes.change_file(%Notes.File{}))
    |> get_days_info()
    {:ok, socket}
  end

  def handle_event("edit_commit", _value, %{assigns: %{editing: false}} = socket) do
    {:noreply, assign(socket, :editing, true)}
  end

  def handle_event("edit_commit", %{"file" => %{"content" => content}}, socket) do
    Github.commit_and_push_file(socket.assigns, content)
    socket = socket
    |> assign(:editing, false)

    {:noreply, socket}
  end

  defp get_days_info(socket) do
    socket
    |> assign(:editing, false)
    |> get_file_info()
    |> get_commit_info()
  end

  defp get_file_info(socket) do
    current_file = Notes.get_file_by_date(socket.assigns.user.id, socket.assigns.date)

    socket
    |> assign(:file, current_file)
  end

  defp get_commit_info(socket) do
    days_commits = Commits.get_commits_by_date(socket.assigns.user.id, socket.assigns.date)

    socket
    |> assign(:commits, days_commits)
  end

  def decode_file(file) do
    file.topic_entries
    |> Enum.sort(&(&1.file_location <= &2.file_location))
    |> Enum.map(& &1.topic.heading <> (&1.content |> Base.decode64!(ignore: :whitespace)))
    |> Enum.reduce(fn entry, file_content ->
      file_content <> entry
    end)
  end

  def display_date(date) do
    diff = Date.diff(date, Date.utc_today())
    cond do
      diff == 0 ->
        "Today"
      diff == -1 ->
        "Yesterday"
      diff <= -2 && diff > -7 ->
        "Last #{Date.day_of_week(date) |> day_name()}"
      diff >= 2 && diff < 7 ->
        "#{Date.day_of_week(date) |> day_name()}"
      diff == 1 ->
        "Tomorrow"
      true ->
        date
    end
  end

  defp day_name(day_number) do
    cond do
      day_number == 1 -> "Monday"
      day_number == 2 -> "Tuesday"
      day_number == 3 -> "Wednesday"
      day_number == 4 -> "Thursday"
      day_number == 5 -> "Friday"
      day_number == 6 -> "Saturday"
      day_number == 7 -> "Sunday"
    end
  end
end
