defmodule GitNotes.GitRepos.GitRepo do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}

  schema "repos" do
    field :name, :string
    field :private, :boolean
    belongs_to :user, GitNotes.Accounts.User, foreign_key: :user_id
    has_many :commits, GitNotes.Commits.Commit

    timestamps()
  end

  def changeset(repo, attrs) do
    repo
    |> cast(attrs, [:name, :id, :private])
    |> unique_constraint(:id, name: :repos_pkey)
    |> validate_required([:id])
  end

  def new_repo_changeset(repo, attrs) do
    repo
    |> cast(attrs, [:name, :user_id, :id, :private])
    |> foreign_key_constraint(:user_id)
    |> validate_required([:id, :user_id, :name])
    |> unique_constraint(:id, name: :repos_pkey)
  end
end
