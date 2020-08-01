defmodule GitNotes.Notes.NotesRepo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes_repos" do
    belongs_to :repo, GitNotes.GitRepos.GitRepo, foreign_key: :repo_id
    belongs_to :user, GitNotes.Accounts.User, foreign_key: :user_id
    has_many :files, GitNotes.Notes.File

    timestamps()
  end

  @required [:repo_id, :user_id]

  @doc false
  def new_changeset(notes_repo, attrs) do
    notes_repo
    |> cast(attrs, [:user_id, :repo_id])
    |> foreign_key_constraint(:repo_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:repo_id], name: :notes_repos_repo_id_index)
    |> unique_constraint([:user_id], name: :notes_repos_user_id_index)
    |> validate_required(@required)
  end

  def update_changeset(notes_repo, attrs) do
    notes_repo
    |> cast(attrs, [:repo_id])
    |> foreign_key_constraint(:repo_id)
    |> unique_constraint([:repo_id], name: :notes_repos_repo_id_index)
    |> validate_required(@required)
  end
end
