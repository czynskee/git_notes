defmodule GitNotes.Notes.Topic do
  use Ecto.Schema
  import Ecto.Changeset

  schema "topics" do
    field :name, :string
    belongs_to :file, GitNotes.Notes.File, foreign_key: :file_id

    timestamps()
  end

  @doc false
  def changeset(topic, attrs) do
    topic
    |> cast(attrs, [:name, :file_id])
    |> foreign_key_constraint(:file_id)
    |> unique_constraint([:name, :file_id])
    |> validate_required([:name, :file_id])
  end
end
