defmodule GitNotes.Repo.Migrations.CreateCommits do
  use Ecto.Migration



  def change do
    create table(:commits) do
      add :sha, :string, null: false
      add :ref, :string, null: false
      add :message, :text, null: false
      add :distinct, :boolean
      add :author, :string, null: false
      add :git_repo_id, references(:repos, on_delete: :delete_all)
      add :commit_date, :date, null: false

      timestamps()
    end

    create unique_index(:commits, [:sha])
    create index(:commits, [:git_repo_id, :commit_date])
  end
end
