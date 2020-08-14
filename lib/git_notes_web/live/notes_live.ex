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
    socket = if term === "" do
      socket
      |> clear_search_topics()
    else
      search_topics = socket.assigns.topics
      |> Enum.filter(& String.starts_with?(&1.name |> String.downcase(), term))

      socket
      |> assign(:search_topics, search_topics)
      |> assign(:search_term, term)
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

    {:noreply, socket}
  end

  def handle_event("select_topic", %{"direction" => "up"}, socket) do
    %{search_topic_index: index} = socket.assigns
    index = index - 1
    index = (index >= 0 && index) || 0
    socket = socket
    |> assign(:search_topic_index, index)

    {:noreply, socket}
  end

  def handle_event("insert_topic", %{"location" => location, "content" => content}, socket) do
    %{search_topic_index: index, search_topics: topics, search_term: term} = socket.assigns

    topic = Enum.at(topics, index)
    topic_content = Notes.get_topic_content(topic)

    term_length = String.length(term) + 1

    content = String.slice(content, 0, location - term_length) <> "\n#{topic_content}" <> String.slice(content, location, String.length(content))

    socket = socket
    |> assign(:file, Map.put(socket.assigns.file, :content, Base.encode64(content)))
    |> clear_search_topics()
    {:noreply, socket}
  end



  defp clear_search_topics(socket) do

    socket
    |> assign(:search_topics, [])
    |> assign(:search_topic_index, 0)
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
