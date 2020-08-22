defmodule GitNotesWeb.DayComponent do
  use GitNotesWeb, :live_component

  alias GitNotes.{Notes, Github}


  def mount(socket) do
    {:ok, socket}
  end


  def update(assigns, socket) do
    socket = socket
    |> Map.put(:assigns, Map.merge(socket.assigns, assigns))
    |> assign(:file_changeset, Notes.change_file(%Notes.File{}))
    |> assign(:editing, false)

    {:ok, socket}
  end

  def preload(list_of_assigns) do
    lower = List.first(list_of_assigns).id
    upper = List.last(list_of_assigns).id
    user_id = List.first(list_of_assigns).user_id
    {commits, files} = Notes.get_file_and_commit_date_range(user_id, lower, upper)

    list_of_assigns
    |> Enum.map(fn %{id: date} = assigns ->
      commits = Enum.filter(commits, & &1.commit_date == date)
      file = Enum.filter(files, & &1.file_name_date == date) |> Enum.at(0)

      assigns
      |> Map.put(:commits, commits)
      |> Map.put(:file, file)
    end)
  end


  def handle_event("edit_commit", _value, %{assigns: %{editing: false}} = socket) do
    {:noreply, assign(socket, :editing, true)}
  end

  def handle_event("edit_commit", %{"file" => %{"content" => content}}, socket) do
    Task.start(fn -> Github.commit_and_push_file(socket.assigns, content) end)
    socket = socket
    |> assign(:editing, false)

    IO.inspect socket

    {:noreply, socket}
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
