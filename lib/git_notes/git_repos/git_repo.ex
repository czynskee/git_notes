defmodule GitNotes.GitRepos.GitRepo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}

  schema "repos" do
    field :name, :string
    field :notes_repo, :boolean
    belongs_to :user, GitNotes.Accounts.User
    # belongs_to :visibility, GitNotes.GitRepos.Visibility

    timestamps()
  end

  def changeset(repo, attrs) do
    repo
    |> cast(attrs, [:name, :user_id, :id, :notes_repo])
    |> validate_required([:id])
  end

  def new_repo_changeset(repo, attrs) do
    repo
    |> cast(attrs, [:name, :user_id, :id])
    |> foreign_key_constraint(:user_id)
    |> validate_required([:id, :user_id, :name])
  end
end
