defmodule GitNotes.Repo.Migrations.CreateNotesRepos do
  use Ecto.Migration

  def change do
    create table(:notes_repos) do
      add :repo_id, references(:repos, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:notes_repos, [:user_id], name: :notes_repos_user_id_index)
    create unique_index(:notes_repos, [:repo_id], name: :notes_repos_repo_id_index)
  end
end
