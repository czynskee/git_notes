defmodule GitNotes.Notes do
  alias GitNotes.Repo
  alias GitNotes.Notes.{File, Topic, TopicEntry}
  alias GitNotes.Accounts
  alias GitNotes.GitRepos

  import Ecto.Query

  def create_file(attrs) do
    %File{}
    |> File.changeset(attrs)
    |> Repo.insert!()
  end

  def update_file(%File{} = file, attrs) do
    file
    |> Repo.preload(:topic_entries)
    |> File.update_changeset(attrs)
    |> Repo.update!()
  end

  def create_or_update_file(attrs, user_id) do
    entries = find_topic_entries(attrs["content"])
    entries = if length(entries) == 0 do
      default_entry(attrs["content"])
    else entries
    end
    |> create_topics_from_entries(user_id)

    attrs = Map.put(attrs, "topic_entries", entries)

    case get_file_by(attrs["git_repo_id"], %{name: attrs["name"]}) do
      nil -> create_file(attrs)
      file -> update_file(file, attrs)
    end
  end

  def default_entry(content) do
    ("# Today\n" <> Base.decode64!(content, ignore: :whitespace) ) |> Base.encode64 |> find_topic_entries
  end

  def create_topics_from_entries(topic_entries, user_id) do
    topic_entries
    |> Enum.map(fn {heading, name, {location, content}} ->
      topic = case get_user_topic_by_name(user_id, name) do
        nil ->
          create_topic(%{heading: heading, name: name, user_id: user_id}) |> elem(1)
        topic -> topic
      end
      %{file_location: location, content: content |> Base.encode64(), topic_id: topic.id}
    end)
  end

  def find_topic_entries(file_content) do
    decoded_content = Base.decode64!(file_content, ignore: :whitespace)
    topic_delims = Regex.scan(~r/#+ (.+?)(?=\n|$)/m, decoded_content, return: :index)
    |> Enum.map(fn [{pattern_start, _pattern_length}, {capture_start, length}] -> {pattern_start, capture_start, capture_start + length} end)

    entry_delims = topic_delims
    |> Enum.with_index()
    |> Enum.map(fn {{_first, _start, last}, index} ->
      entry_start = last + 1
      {entry_end, _, _} = Enum.at(topic_delims, index + 1) || {String.length(decoded_content), nil, nil}
      {entry_start, entry_end - 1}
    end)

    Enum.zip(topic_delims, entry_delims)
    |> Enum.map(fn {{heading_start, topic_start, topic_end}, {entry_start, entry_end}} ->
      { String.slice(decoded_content, heading_start..topic_end),
        String.slice(decoded_content, topic_start..topic_end) |> String.trim(),
      {entry_start, String.slice(decoded_content, entry_start..entry_end)}}
    end)
  end


  def list_user_files(%Accounts.User{id: id}) do
    list_user_files(id)
  end

  def list_user_files(user_id) when is_integer(user_id) do
    Repo.all user_files_query(user_id)
  end

  def list_repo_files(repo_id) when is_integer(repo_id) do
    Repo.all repo_files_query(repo_id)
  end

  def get_file_and_commit_date_range(user_id, lower, upper) do
    commits = (from c in GitNotes.Commits.Commit,
    join: r in assoc(c, :git_repo),
    join: u in assoc(r, :user), on: u.id == ^user_id,
    where: c.commit_date >= ^lower and c.commit_date <= ^upper
    )
    |> Repo.all()

    files = (from f in File,
    join: e in assoc(f, :topic_entries),
    join: t in assoc(e, :topic),
    join: r in assoc(f, :git_repo),
    join: u in assoc(r, :user), on: u.id == ^user_id and u.notes_repo_id == r.id,
    where: f.file_name_date >= ^lower and f.file_name_date <= ^upper,
    preload: [topic_entries: {e, topic: t}]
    )
    |> Repo.all()

    {commits, files}
  end

  alias Ecto

  def get_file_by(repo_id, params) do
    params = Map.put(params, :git_repo_id, repo_id)
    Repo.get_by(File, params)
  end

  def get_file_by_date(user_id, date) do
    (from f in File,
    join: e in assoc(f, :topic_entries),
    join: t in assoc(e, :topic),
    where: t.user_id == ^user_id,
    where: f.file_name_date == ^date,
    preload: [topic_entries: {e, topic: t}])
    |> Repo.one()
  end

  defp user_files_query(user_id) do
    from f in File,
    join: u in Accounts.User, on: f.git_repo_id == u.notes_repo_id,
    where: u.id == ^user_id,
    select: f
  end

  defp repo_files_query(repo_id) do
    from r in GitRepos.GitRepo,
    join: f in File, on: f.git_repo_id == r.id,
    where: r.id == ^repo_id,
    select: f
  end

  def delete_file(file) do
    Repo.delete!(file)
  end

  def get_file(file_id) when is_integer(file_id) do
    Repo.get(File, file_id)
  end

  def get_file(%File{} = file) do
    get_file(file.id)
  end



  def delete_user_files(user_id) do
    Repo.delete_all user_files_query(user_id)
  end

  def change_file(%File{} = file, attrs \\ %{}) do
    File.changeset(file, attrs)
  end

  def change_update_file(%File{} = file, attrs \\ %{}) do
    file
    |> Repo.preload(:topic_entries)
    |> File.update_changeset(attrs)
  end

  def preload_file_associations(%File{} = file) do
    file
    |> Repo.preload([topic_entries: :topic])
  end

  def preload_topic_entries(%Topic{} = topic) do
    topic
    |> Repo.preload([topic_entries: :file])
  end


  @doc """
  Returns the list of topics.

  ## Examples

      iex> list_topics()
      [%Topic{}, ...]

  """
  def list_topics do
    Repo.all(Topic)
  end

  def list_user_topics(user_id) do
    user_topics_query(user_id)
    |> Repo.all()
  end

  def user_topics_query(user_id) do
    (from t in Topic,
     where: t.user_id == ^user_id,
     select: t)
  end

  def user_topic_by_name_query(user_id, name) do
    (from t in user_topics_query(user_id),
    where: t.name == ^name)
  end

  def get_user_topic_by_name(user_id, name) do
    user_topic_by_name_query(user_id, name)
    |> Repo.one()
  end

  def get_latest_entry_of_topic(user_id, topic, date) do
    query = user_topic_by_name_query(user_id, topic.name)
    |> exclude(:select)
    (from t in query,
    join: e in TopicEntry, on: e.topic_id == t.id,
    join: f in File, on: e.file_id == f.id,
    where: f.file_name_date <= ^date,
    order_by: [desc: f.file_name_date],
    limit: 1,
    select: e
    )
    |> Repo.one()
  end



  @doc """
  Gets a single topic.

  Raises `Ecto.NoResultsError` if the Topic does not exist.

  ## Examples

      iex> get_topic!(123)
      %Topic{}

      iex> get_topic!(456)
      ** (Ecto.NoResultsError)

  """
  def get_topic!(id) do
    Repo.get!(Topic, id)
  end

  @doc """
  Creates a topic.

  ## Examples

      iex> create_topic(%{field: value})
      {:ok, %Topic{}}

      iex> create_topic(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_topic(attrs \\ %{}) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a topic.

  ## Examples

      iex> update_topic(topic, %{field: new_value})
      {:ok, %Topic{}}

      iex> update_topic(topic, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a topic.

  ## Examples

      iex> delete_topic(topic)
      {:ok, %Topic{}}

      iex> delete_topic(topic)
      {:error, %Ecto.Changeset{}}

  """
  def delete_topic(%Topic{} = topic) do
    Repo.delete(topic)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking topic changes.

  ## Examples

      iex> change_topic(topic)
      %Ecto.Changeset{data: %Topic{}}

  """
  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end


  @doc """
  Returns the list of topic_entries.

  ## Examples

      iex> list_topic_entries()
      [%TopicEntry{}, ...]

  """
  def list_topic_entries do
    Repo.all(TopicEntry)
  end

  @doc """
  Gets a single topic_entry.

  Raises `Ecto.NoResultsError` if the Topic entry does not exist.

  ## Examples

      iex> get_topic_entry!(123)
      %TopicEntry{}

      iex> get_topic_entry!(456)
      ** (Ecto.NoResultsError)

  """
  def get_topic_entry!(id), do: Repo.get!(TopicEntry, id)

  @doc """
  Creates a topic_entry.

  ## Examples

      iex> create_topic_entry(%{field: value})
      {:ok, %TopicEntry{}}

      iex> create_topic_entry(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_topic_entry(attrs \\ %{}) do
    %TopicEntry{}
    |> TopicEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a topic_entry.

  ## Examples

      iex> update_topic_entry(topic_entry, %{field: new_value})
      {:ok, %TopicEntry{}}

      iex> update_topic_entry(topic_entry, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_topic_entry(%TopicEntry{} = topic_entry, attrs) do
    topic_entry
    |> TopicEntry.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a topic_entry.

  ## Examples

      iex> delete_topic_entry(topic_entry)
      {:ok, %TopicEntry{}}

      iex> delete_topic_entry(topic_entry)
      {:error, %Ecto.Changeset{}}

  """
  def delete_topic_entry(%TopicEntry{} = topic_entry) do
    Repo.delete(topic_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking topic_entry changes.

  ## Examples

      iex> change_topic_entry(topic_entry)
      %Ecto.Changeset{data: %TopicEntry{}}

  """
  def change_topic_entry(%TopicEntry{} = topic_entry, attrs \\ %{}) do
    TopicEntry.changeset(topic_entry, attrs)
  end
end
