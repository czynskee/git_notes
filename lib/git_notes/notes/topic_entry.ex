defmodule GitNotes.Notes.TopicEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topic_entries" do
    field :content, :string
    field :file_location, :integer
    belongs_to :file, GitNotes.Notes.File, foreign_key: :file_id
    belongs_to :topic, GitNotes.Notes.Topic, foreign_key: :topic_id

    timestamps()
  end

  @doc false
  def changeset(topic_entry, attrs) do
    topic_entry
    |> cast(attrs, [:content, :topic_id, :file_id, :file_location])
    |> validate_required([:content, :topic_id, :file_id, :file_location])
    |> compress_content()
  end

  defp compress_content(changeset) do
    changeset
    |> put_change(:content, Base.encode64(changeset.changes.content))
  end
end
