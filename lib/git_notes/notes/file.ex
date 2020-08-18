defmodule GitNotes.Notes.File do
  use Ecto.Schema
  import Ecto.Changeset

  alias GitNotes.Notes

  schema "files" do
    field :name, :string
    field :file_name_date, :date
    field :content, :string, virtual: true
    belongs_to :git_repo, GitNotes.GitRepos.GitRepo, foreign_key: :git_repo_id
    has_many :topic_entries, GitNotes.Notes.TopicEntry, on_replace: :delete

    timestamps()
  end

  # All filenames must be in this format: YYYY-MM-DD
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:name, :git_repo_id, :content])
    |> validate_required([:name, :git_repo_id, :content])
    |> unique_constraint([:git_repo_id, :name])
    |> validate_filename_date()
    |> put_filename_date()
    |> find_and_add_topic_entries()
  end


  def update_changeset(file, attrs) do
    file
    |> cast(attrs, [:content])
    |> validate_required([:content])
    |> find_and_add_topic_entries()
  end

  defp find_and_add_topic_entries(changeset) do
    if changeset.changes[:content] do
      repo_id = changeset.changes[:git_repo_id] || changeset.data.git_repo_id
      file_date = changeset.changes[:file_name_date] || changeset.data.file_name_date
      user = GitNotes.Accounts.get_user_by(%{notes_repo_id: repo_id})

      topic_entries =
      find_topic_entries(changeset.changes.content)
      |> Notes.create_topics_from_entries(user.id, file_date)
      |> Enum.map(fn {topic, {entry_location, entry_content}} ->
        %Notes.TopicEntry{
          file_location: entry_location,
          content: entry_content |> Base.encode64,
          topic_id: topic.id,
        }
      end)

      changeset
      |> put_change(:topic_entries, topic_entries)
      |> cast_assoc(:topic_entries, with: &Notes.TopicEntry.changeset/2)
    else
      changeset
    end
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

  defp validate_filename_date(changeset, options \\ []) do
    validate_change(changeset, :name, fn _, name ->
      case Regex.run(~r/\d\d\d\d-\d\d-\d\d/, name) do
        nil ->
          [{:name, options[:message] || "filename does not conform to date format"}]
        matches ->
          case extract_name_into_date(Enum.at(matches, 0)) do
            {:ok, _date} ->
              []
            {:error, _reason} ->
              [{:name, options[:message] || "date is not a real date"}]
          end
      end
    end)
  end

  defp extract_name_into_date(name) do
    [year, month, day] = name
    |> String.split("-")
    |> Enum.map(& Integer.parse &1)
    |> Enum.map(& elem &1, 0 )

    Date.new(year, month, day)
  end

  defp put_filename_date(changeset) do
    if changeset.valid? do
      {:ok, date} =
      get_change(changeset, :name)
      |> String.split(".")
      |> Enum.at(0)
      |> extract_name_into_date()

      put_change(changeset, :file_name_date, date)
    else
      changeset
    end

  end
end
