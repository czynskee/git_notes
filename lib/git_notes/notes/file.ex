defmodule GitNotes.Notes.File do
  use Ecto.Schema
  import Ecto.Changeset

  schema "files" do
    field :content, :string
    field :name, :string
    field :file_name_date, :date
    belongs_to :git_repo, GitNotes.GitRepos.GitRepo, foreign_key: :git_repo_id
    has_many :topics, GitNotes.Notes.Topic

    timestamps()
  end

  # All filenames must be in this format: YYYY-MM-DD
  def changeset(file, attrs) do
    file
    |> cast(attrs, [:name, :content, :git_repo_id])
    |> validate_required([:name, :content, :git_repo_id])
    |> validate_filename_date(:name)
    |> unique_constraint([:git_repo_id, :name])
  end

  def update_changeset(file, attrs) do
    file
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end

  defp validate_filename_date(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, name ->
      case Regex.run(~r/\d\d\d\d-\d\d-\d\d/, name) do
        nil ->
          [{field, options[:message] || "filename does not conform to date format"}]
        matches ->
          case extract_name_into_date(Enum.at(matches, 0)) do
            {:ok, _date} ->
              []
            {:error, _reason} ->
              [{field, options[:message] || "date is not a real date"}]
          end
      end
    end)

    if changeset.valid? do
      put_filename_date(changeset)
    else changeset
    end
  end

  defp extract_name_into_date(name) do
    [year, month, day] = name
    |> String.split("-")
    |> Enum.map(& Integer.parse &1)
    |> Enum.map(& elem &1, 0 )

    Date.new(year, month, day)
  end

  defp put_filename_date(changeset) do
    {:ok, date} =
    get_change(changeset, :name)
    |> String.split(".")
    |> Enum.at(0)
    |> extract_name_into_date()


    put_change(changeset, :file_name_date, date)
  end
end
