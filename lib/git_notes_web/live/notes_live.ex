defmodule GitNotesWeb.NotesLive do
  use Phoenix.LiveView
  use Phoenix.HTML
  alias GitNotes.{Accounts, Notes, Github}

  def render(assigns) do
    GitNotesWeb.NotesView.render("notes_live.html", assigns)
  end

  def mount(_params, session, socket) do
    GitNotesWeb.Endpoint.subscribe("user: #{session["user_id"]}")
    date_range = Date.range(Date.add(Date.utc_today(), -2), Date.add(Date.utc_today(), 2))
    |> Enum.to_list()

    socket = socket
    |> assign(:user, Accounts.get_user(session["user_id"]))
    |> assign(:date_range, date_range)
    |> assign(:changeset, Notes.change_file(%Notes.File{}))
    |> get_topic_info()
    |> clear_search_topics()

    {:ok, fetch_day_info(socket)}
  end

  defp clear_search_topics(socket) do

    socket
    |> assign(:search_topics, [])
    |> assign(:search_topic_index, 0)
    |> assign(:search_topic_entry_index, 0)
  end

  defp get_topic_info(socket) do
    topics = Notes.list_user_topics(socket.assigns.user.id)

    socket
    |>assign(:topics, topics)
  end

  @spec fetch_day_info(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def fetch_day_info(socket) do
    lower = List.first(socket.assigns.date_range)
    upper = List.last(socket.assigns.date_range)
    user_id = socket.assigns.user.id

    {commits, files} = Notes.get_file_and_commit_date_range(user_id, lower, upper)

    date_info = socket.assigns.date_range
    |> Enum.map(fn date ->
      commits = Enum.filter(commits, & &1.commit_date == date)
      file = Enum.filter(files, & &1.file_name_date == date) |> Enum.at(0)

      %{
        date: date,
        commits: commits,
        file: file
      }
    end)

    assign(socket, :date_info, date_info)
  end

  def handle_info(%{event: "new_commits", payload: %{"commits" => _commits}}, socket) do
    {:noreply, fetch_day_info(socket)}
  end

  def handle_info(%{event: "file_change", payload: %{"files" => _files}}, socket) do
    {:noreply, fetch_day_info(socket)}
  end

  def handle_event("edit_commit", %{"file" => %{"content" => content, "date" => date}}, socket) do
    Task.start(fn -> Github.commit_and_push_file(content, socket.assigns.user, date) end)

    {:noreply, socket}
  end

  # def handle_event("change_range", value, socket) do
  #   IO.inspect value

  #   {:noreply, socket}
  # end

  def handle_event("change_range", %{"direction" => direction}, socket) do
    amount = if direction == "back", do: -1, else: 1
    socket = assign(socket, :date_range, Enum.map(socket.assigns.date_range, & Date.add(&1, amount)))
    {:noreply, fetch_day_info(socket)}
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



end

#   def mount(_params, session, socket) do
#     GitNotesWeb.Endpoint.subscribe("user: #{session["user_id"]}")
#     date_range = Date.range(Date.add(Date.utc_today(), -2), Date.add(Date.utc_today(), 2))

#     socket = socket
#     |> assign(:user, Accounts.get_user(session["user_id"]))
#     |> assign(:add_date_action, "append")
#     |> assign(:date_range, date_range)
#     |> get_topic_info()
#     |> clear_search_topics()

#     {:ok, socket}
#   end


#   def handle_info(%{event: "new_commits", payload: %{"commits" => commits}}, socket) do
#     for commit <- commits do
#       send_update GitNotesWeb.DayComponent, id: commit.commit_date, user_id: socket.assigns.user.id
#     end
#     {:noreply, socket}
#   end

#   def handle_info(%{event: "file_change", payload: %{"files" => files}}, socket) do
#     for file <- files do
#       send_update GitNotesWeb.DayComponent, id: file.file_name_date, user_id: socket.assigns.user.id
#     end
#     {:noreply, socket}
#   end

#   def handle_event("change_range", %{"new_date" => date, "add_date_action" => action}, socket) do
#     socket = socket
#     |> assign(:add_date_action, action)
#     |> assign(:date_range, [Date.from_iso8601!(date)])

#     {:reply, %{}, socket}
#   end

#   def handle_event("refresh_files", _value, socket) do
#     Github.populate_notes(socket.assigns.user.notes_repo_id)
#     {:noreply, socket}
#   end


# end
