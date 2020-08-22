defmodule GitNotes.Notes.TopicEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topic_entries" do
    field :content, :string, default: ""
    field :file_location, :integer
    belongs_to :file, GitNotes.Notes.File, foreign_key: :file_id
    belongs_to :topic, GitNotes.Notes.Topic, foreign_key: :topic_id

    timestamps()
  end

  @doc false
  def changeset(topic_entry, attrs) do
    topic_entry
    |> cast(attrs, [:content, :topic_id, :file_id, :file_location])
    |> validate_required([:topic_id, :file_id, :file_location])
  end

  def from_file_changeset(topic_entry, attrs) do
    topic_entry
    |> Map.put(:empty_values, [])
    |> cast(attrs, [:content, :topic_id, :file_id, :file_location])
    |> validate_required([:file_location, :topic_id])
  end

  defp validate_not_nil(changeset, fields) do
    Enum.reduce(fields, changeset, fn field, changeset ->
      if get_field(changeset, field) == nil do
        add_error(changeset, field, "nil")
      else
        changeset
      end
    end)
  end

end
