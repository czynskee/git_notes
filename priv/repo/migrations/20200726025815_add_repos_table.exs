defmodule GitNotes.Repo.Migrations.AddReposTable do
  use Ecto.Migration

  def change do
    create table(:repos) do
      add :name, :string, null: false
      add :notes_repo, :boolean
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps()
    end

    create index(:repos, [:user_id])
  end
end
