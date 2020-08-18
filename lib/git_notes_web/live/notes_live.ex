defmodule GitNotesWeb.NotesLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias GitNotes.{Accounts, Notes, Commits, Github}

  def render(assigns) do
    GitNotesWeb.NotesView.render("notes_live.html", assigns)
  end

  def mount(_params, session, socket) do
    GitNotesWeb.Endpoint.subscribe("user: #{session["user_id"]}")

    socket = socket
    |> assign(:user_id, session["user_id"])
    |> assign(:file_changeset, Notes.change_file(%Notes.File{}))
    |> clear_search_topics()

    {:ok, get_days_info(socket, Date.utc_today())}
  end

  def handle_info(%{event: "new_commits"}, socket) do
    {:noreply, get_commit_info(socket)}
  end

  def handle_info(%{event: "updated_file"}, socket) do

    socket = socket
    |> get_file_info()
    |> get_topic_info()
    {:noreply, socket}
  end

  def handle_event("commit_notes", _value, %{assigns: %{editing: false}} = socket) do
    socket = socket
    |> assign(:editing, true)

    {:noreply, socket}
  end

  def handle_event("commit_notes", %{"file" => %{"content" => content}}, socket) do
    Github.commit_and_push_file(socket.assigns, content)
    socket = socket
    |> assign(:editing, false)

    {:noreply, socket}
  end

  def handle_event("previous_day", _value, socket) do
    previous_date = Date.add(socket.assigns.date, -1)

    {:noreply, get_days_info(socket, previous_date)}
  end

  def handle_event("next_day", _value, socket) do
    next_date = Date.add(socket.assigns.date, 1)

    {:noreply, get_days_info(socket, next_date)}
  end

  def handle_event("refresh_files", _value, socket) do
    Github.populate_notes(socket.assigns.user.notes_repo_id)
    {:noreply, socket}
  end

  def handle_event("search_term", %{"term" => term}, socket) do
    socket =
    if term === "" do
      socket
      |> clear_search_topics()
    else
      search_topics = socket.assigns.topics
      |> Enum.filter(& String.starts_with?(&1.name |> String.downcase(), term))
      |> Enum.map(& Notes.preload_topic_entries(&1))

      search_topic_index = socket.assigns.search_topic_index

      search_topic_index =
      if search_topic_index > length(search_topics) - 1 do
        length(search_topics) - 1
      else search_topic_index
      end

      socket
      |> assign(:search_topics, search_topics)
      |> assign(:search_term, term)
      |> assign(:search_topic_index, search_topic_index)
    end

    {:noreply, socket}
  end

  def handle_event("select_topic", %{"direction" => "down"}, socket) do
    %{search_topic_index: index, search_topics: topics} = socket.assigns
    index = index + 1
    num_topics = length(topics)

    index = (index < num_topics && index) || num_topics - 1
    socket = socket
    |> assign(:search_topic_index, index)
    |> assign(:search_topic_entry_index, 0)

    {:noreply, socket}
  end

  def handle_event("select_topic", %{"direction" => "up"}, socket) do
    %{search_topic_index: index} = socket.assigns
    index = index - 1
    index = (index >= 0 && index) || 0
    socket = socket
    |> assign(:search_topic_index, index)
    |> assign(:search_topic_entry_index, 0)

    {:noreply, socket}
  end

  def handle_event("select_topic", %{"direction" => "left"}, socket) do
    %{search_topic_entry_index: index} = socket.assigns
    index = index - 1
    index = (index >= 0 && index) || 0
    socket = socket
    |> assign(:search_topic_entry_index, index)

    {:noreply, socket}
  end

  def handle_event("select_topic", %{"direction" => "right"}, socket) do
    %{search_topic_entry_index: index, search_topics: topics, search_topic_index: topic_index} = socket.assigns

    topic = Enum.at(topics, topic_index)

    index = index + 1
    num_entries = length(topic.topic_entries)

    index = (index < num_entries && index) || num_entries - 1
    socket = socket
    |> assign(:search_topic_entry_index, index)

    {:noreply, socket}
  end

  def handle_event("insert_topic", %{"location" => location, "content" => content}, socket) do
    %{user: user, file: file, date: date, search_topic_index: index, search_topics: topics, search_topic_entry_index: topic_entry_index} = socket.assigns

    topic = Enum.at(topics, index)

    topic_entry_content =
    Notes.preload_topic_entries(topic)
    |> Map.get(:topic_entries)
    |> Enum.reverse()
    |> Enum.at(topic_entry_index)
    # topic_entry_content = Notes.get_latest_entry_of_topic(user.id, topic, date)
    |> Map.get(:content)
    |> Base.decode64!()

    first = String.slice(content, 1..location)
    middle = topic.heading <> topic_entry_content
    last = String.slice(content, location, String.length(content))

    content = first <> middle <> last

    file = case file do
      nil ->
        Notes.change_file(%Notes.File{},
        %{name: Date.to_string(date) <> ".md", git_repo_id: user.notes_repo_id, content: content |> Base.encode64()})
      file -> Notes.change_update_file(file, %{content: content |> Base.encode64()})
    end
    |> Ecto.Changeset.apply_changes()
    |> Notes.preload_file_associations()

    socket = socket
    |> clear_search_topics()
    |> assign(:file, file)
    {:noreply, socket}
  end

  defp clear_search_topics(socket) do

    socket
    |> assign(:search_topics, [])
    |> assign(:search_topic_index, 0)
    |> assign(:search_topic_entry_index, 0)
  end

  defp get_days_info(socket, date) do
    user_id = socket.assigns.user_id

    socket
    |> assign(:date, date)
    |> assign(:editing, true)
    |> assign(:user, Accounts.get_user(user_id))
    |> get_file_info()
    |> get_commit_info()
    |> get_topic_info()
  end

  defp get_commit_info(socket) do
    days_commits = Commits.get_commits_by_date(socket.assigns.user.id, socket.assigns.date)

    socket
    |> assign(:commits, days_commits)
  end

  defp get_file_info(socket) do
    current_file = Notes.get_file_by_date(socket.assigns.user.id, socket.assigns.date)

    socket
    |> assign(:file, current_file)
  end

  defp get_topic_info(socket) do
    topics = Notes.list_user_topics(socket.assigns.user.id)

    socket
    |>assign(:topics, topics)
  end
end
