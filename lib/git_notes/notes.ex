defmodule GitNotes.Notes do
  alias GitNotes.Notes.NotesRepo
  alias GitNotes.Repo
  alias GitNotes.Notes.File
  alias GitNotes.Accounts
  alias GitNotes.GitRepos

  import Ecto.Query

  def create_notes_repo(attrs) do
    %NotesRepo{}
    |> NotesRepo.new_changeset(attrs)
    |> Repo.insert()
  end

  def get_notes_repo(%NotesRepo{id: id}) do
    get_notes_repo(id)
  end

  def get_notes_repo(id) when is_integer(id) do
    Repo.get(NotesRepo, id)
  end

  def get_notes_repo_for_user(user_id) when is_integer(user_id)  do
    Repo.get_by(NotesRepo, user_id: user_id)
  end

  def get_notes_repo_for_user(%Accounts.User{id: id}) do
    get_notes_repo_for_user(id)
  end

  def get_notes_repo_for_gitrepo(repo_id) when is_integer(repo_id) do
    Repo.get_by(NotesRepo, repo_id: repo_id)
  end

  def get_notes_repo_for_gitrepo(%GitRepos.GitRepo{id: id}) do
    get_notes_repo_for_gitrepo(id)
  end

  def update_notes_repo(%NotesRepo{} = notes_repo, attrs) do
    notes_repo
    |> NotesRepo.update_changeset(attrs)
    |> Repo.update()
  end

  def delete_notes_repo(%NotesRepo{} = notes_repo) do
    Repo.delete(notes_repo)
  end

  def create_file(attrs) do
    %File{}
    |> File.changeset(attrs)
    |> Repo.insert()
  end

  def list_files_for_user(%Accounts.User{id: id}) do
    list_files_for_user(id)
  end

  def list_files_for_user(user_id) when is_integer(user_id) do
    (from u in Accounts.User,
    join: n in NotesRepo, on: u.id == n.user_id,
    join: f in File, on: f.notes_repo_id == n.id,
    where: u.id == ^user_id,
    select: f)
    |> Repo.all()
  end

  def delete_file(file) do
    Repo.delete(file)
  end

  def get_file(file_id) when is_integer(file_id) do
    Repo.get(File, file_id)
  end

  def get_file(%File{} = file) do
    get_file(file.id)
  end

  def get_repo_file_by(%NotesRepo{} = notes_repo, attrs) do
    Repo.get_by(File, Map.put(attrs, :notes_repo_id, notes_repo.id))
  end

  def update_file(%File{} = file, attrs) do
    file
    |> File.update_changeset(attrs)
    |> Repo.update()
  end

end
