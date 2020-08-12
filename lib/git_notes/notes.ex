defmodule GitNotes.Notes do
  alias GitNotes.Repo
  alias GitNotes.Notes.File
  alias GitNotes.Accounts
  alias GitNotes.GitRepos

  import Ecto.Query

  def create_file(attrs) do
    %File{}
    |> File.changeset(attrs)
    |> Repo.insert!()
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

  def get_file_by(repo_id, params) do
    params = Map.put(params, :git_repo_id, repo_id)
    Repo.get_by(File, params)
  end

  def get_file_by_date(user_id, date) do
    query = user_files_query(user_id)
    (from f in query,
    where: f.file_name_date == ^date,
    order_by: [desc: f.file_name_date],
    limit: 1)
    |> Repo.all
    |> Enum.at(0)
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

  def update_file(%File{} = file, attrs) do
    file
    |> File.update_changeset(attrs)
    |> Repo.update!()
  end

  def delete_user_files(user_id) do
    Repo.delete_all user_files_query(user_id)
  end

  def change_file(%File{} = file, attrs \\ %{}) do
    File.changeset(file, attrs)
  end




  alias GitNotes.Notes.Topic

  @doc """
  Returns the list of topics.

  ## Examples

      iex> list_topics()
      [%Topic{}, ...]

  """
  def list_topics do
    Repo.all(Topic)
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
  def get_topic!(id), do: Repo.get!(Topic, id)

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
end
