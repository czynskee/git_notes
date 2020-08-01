defmodule GitNotes.Commits.Commit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "commits" do
    field :sha, :string
    field :ref, :string
    field :message, :string
    field :distinct, :boolean
    field :author, :string
    field :commit_date, :utc_datetime
    belongs_to :git_repo, GitNotes.GitRepos.GitRepo

    timestamps()
  end

  def changeset(commit, attrs) do
    commit
    |> cast(attrs, [:ref, :sha, :commit_date, :message, :sha, :distinct, :author, :git_repo_id])
    |> foreign_key_constraint(:git_repo_id)
    |> validate_required([:ref, :sha, :commit_date, :message, :sha, :author, :git_repo_id])
  end

end
