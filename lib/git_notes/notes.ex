defmodule GitNotes.Notes do
  alias GitNotes.Repo
  alias GitNotes.Notes.File
  alias GitNotes.Accounts
  alias GitNotes.GitRepos

  import Ecto.Query

  def create_file(attrs) do
    %File{}
    |> File.changeset(attrs)
    |> Repo.insert!()
  end

  def list_user_files(%Accounts.User{id: id}) do
    list_user_files(id)
  end

  def list_user_files(user_id) when is_integer(user_id) do
    Repo.all from u in Accounts.User,
    join: f in File, on: f.git_repo_id == u.notes_repo_id,
    where: u.id == ^user_id,
    select: f
  end

  def list_repo_files(repo_id) when is_integer(repo_id) do
    Repo.all repo_files_query(repo_id)
  end

  def get_file_by(repo_id, params) do
    params = Map.put(params, :git_repo_id, repo_id)
    Repo.get_by(File, params)
  end

  defp repo_files_query(repo_id) do
    from r in GitRepos.GitRepo,
    join: f in File, on: f.git_repo_id == r.id,
    where: r.id == ^repo_id,
    select: f
  end

  def delete_file(file) do
    Repo.delete!(file)
  end

  def get_file(file_id) when is_integer(file_id) do
    Repo.get(File, file_id)
  end

  def get_file(%File{} = file) do
    get_file(file.id)
  end

  def update_file(%File{} = file, attrs) do
    file
    |> File.update_changeset(attrs)
    |> Repo.update!()
  end



end
