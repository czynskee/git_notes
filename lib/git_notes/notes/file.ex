defmodule GitNotes.Notes.File do
  use Ecto.Schema
  import Ecto.Changeset

  schema "files" do
    field :content, :string
    field :file_name, :string
    belongs_to :notes_repo, GitNotes.Notes.NotesRepo, foreign_key: :notes_repo_id


    timestamps()
  end

  def changeset(file, attrs) do
    file
    |> cast(attrs, [:file_name, :content, :notes_repo_id])
    |> validate_required([:file_name, :content, :notes_repo_id])
  end

  def update_changeset(file, attrs) do
    file
    |> cast(attrs, [:file_name, :content])
    |> validate_required([:file_name, :content])
  end
end
