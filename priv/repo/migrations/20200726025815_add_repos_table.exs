defmodule GitNotes.Repo.Migrations.AddReposTable do
  use Ecto.Migration

  def change do
    create table(:repos) do
      add :name, :string, null: false
      add :private, :boolean
      add :user_id, references(:users, on_delete: :delete_all), null: false


      timestamps()
    end

    alter table(:users) do
      add :notes_repo_id, references(:repos, on_delete: :nilify_all)
    end

    create index(:repos, [:id])
  end
end
