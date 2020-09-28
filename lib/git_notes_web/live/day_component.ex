defmodule GitNotesWeb.DayComponent do
  use GitNotesWeb, :live_component

  alias GitNotes.{Notes, Github}

  def render(assigns) do
    GitNotesWeb.NotesView.render("day_component.html", assigns)
  end

  def mount(socket) do
    {:ok, socket}
  end

  def update(assigns, socket) do
    socket = assign(socket,
      changeset: Notes.change_file(%Notes.File{}))
      |> clear_search_topics()

    {:ok, assign(socket, assigns)}
  end

  def preload(list_of_assigns) do
    lower = List.first(list_of_assigns).id
    upper = List.last(list_of_assigns).id
    user_id = List.first(list_of_assigns).user.id
    {commits, files} = Notes.get_file_and_commit_date_range(user_id, lower, upper)

    list_of_assigns
    |> Enum.map(fn %{id: date} = assigns ->
      commits = Enum.filter(commits, & &1.commit_date == date)
      file = Enum.filter(files, & &1.file_name_date == date) |> Enum.at(0)

      assigns
      |> Map.put(:commits, commits)
      |> Map.put(:file, file)
      |> Map.put(:changeset, Notes.change_file(%Notes.File{}))
    end)
  end

  defp clear_search_topics(socket) do
    socket
    |> assign(:search_topics, [])
    |> assign(:search_topic_index, 0)
    |> assign(:search_topic_entry_index, 0)
  end

  def handle_event("edit_commit", %{"file" => %{"content" => content}}, socket) do
    Task.start(fn -> Github.commit_and_push_file(content, socket.assigns.user, socket.assigns.date) end)
    socket = socket

    {:noreply, socket}
  end

  def handle_event("search_term", %{"term" => term}, socket) do
    socket =
    if term === "" do
      socket
      |> clear_search_topics()
    else
      search_topics = socket.assigns.topics
      |> Enum.filter(&String.contains?(&1.name |> String.downcase(), term))
      |> Enum.sort_by(&Map.get(&1, :name) |> String.downcase(), fn name1, name2 ->
        if String.starts_with?(name1, term) && !String.starts_with?(name2, term) do
          true
        else false
        end
      end)

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

    cond do
      length(topics) == 0 -> {:noreply, socket}
      index == -1 -> {:noreply, socket}
      true ->
        topic = Enum.at(topics, index)

        topic_entry_content =
        topic
        |> Map.get(:topic_entries)
        |> Enum.reverse()
        |> Enum.at(topic_entry_index)
        |> Map.get(:content)
        |> Base.decode64!()

        first = String.slice(content, 1..location)
        middle = topic.heading <> topic_entry_content
        last = String.slice(content, location, String.length(content))

        entries = Notes.generate_topic_entries_from_content((first <> middle <> last) |> Base.encode64, user.id)

        file = case file do
          nil ->
            Notes.change_file(%Notes.File{},
            %{name: Date.to_string(date) <> ".md", git_repo_id: user.notes_repo_id, topic_entries: entries})
          file -> Notes.change_update_file(file, %{topic_entries: entries})
        end
        |> Ecto.Changeset.apply_changes()
        |> Notes.preload_file_associations()

        socket = socket
        |> clear_search_topics()
        |> assign(:file, file)
        {:noreply, socket}
    end
  end

end
