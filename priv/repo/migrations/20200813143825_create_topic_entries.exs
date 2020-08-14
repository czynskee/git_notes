defmodule GitNotes.Repo.Migrations.CreateTopicEntries do
  use Ecto.Migration

  def change do
    create table(:topic_entries) do
      add :content, :text
      add :file_location, :integer
      add :file_id, references(:files, on_delete: :delete_all), null: false
      add :topic_id, references(:topics, on_delete: :delete_all), null: false

      timestamps()
    end

    create unique_index(:topic_entries, [:file_location, :file_id, :topic_id])
    create index(:topic_entries, [:file_id])
    create index(:topic_entries, [:topic_id])
  end
end
