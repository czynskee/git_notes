defmodule GitNotes.NotesTest do
  use GitNotes.DataCase, async: true

  alias GitNotes.Notes
  alias GitNotes.Notes.NotesRepo
  alias GitNotes.Notes.File


  test "create valid and invalid notes repo entries" do
    %{user: user, repo: repo} = fixtures()

    attrs = %{user_id: user.id, repo_id: repo.id}
    assert {:ok, %NotesRepo{} = notes_repo} = Notes.create_notes_repo(attrs)

    assert notes_repo.repo_id == repo.id
    assert notes_repo.user_id == user.id

    assert {:error, _reason } = Notes.create_notes_repo(attrs)

    second_repo = repo_fixture(%{
      "id" => 54321,
    }, create_user: false)

    assert {:error, _reason} = Notes.create_notes_repo(%{attrs | repo_id: second_repo.id})

    second_user = user_fixture(%{
      installation_id: 456,
      id: 987654,
      login: "other"
    })

    assert {:error, _reason} = Notes.create_notes_repo(%{attrs | user_id: second_user.id})
  end

  test "get notes_repo operations" do
    %{user: user, repo: repo} = fixtures()

    notes_repo = notes_repo_fixture(user, repo)

    assert Notes.get_notes_repo(notes_repo.id) == notes_repo
    assert Notes.get_notes_repo_for_user(user.id) == notes_repo
  end

  test "update notes_repo" do
    %{user: user, repo: repo} = fixtures()

    notes_repo = notes_repo_fixture(user, repo)

    second_repo = repo_fixture(%{"id" => 9999}, create_user: false)

    assert {:ok, notes_repo} = Notes.update_notes_repo(notes_repo, %{repo_id: second_repo.id})

    assert notes_repo.repo_id == 9999

    assert {:error, _reason} = Notes.update_notes_repo(notes_repo, %{repo_id: 555})
  end

  test "delete user or repo does not orphan notes_repo" do
    %{user: user, repo: repo} = fixtures()

    notes_repo = notes_repo_fixture(user, repo)

    GitNotes.GitRepos.delete_repo(repo)

    assert Notes.get_notes_repo(notes_repo) == nil

    repo = repo_fixture(%{}, create_user: false)

    notes_repo = notes_repo_fixture(user, repo)

    GitNotes.Accounts.delete_user(user)

    assert Notes.get_notes_repo(notes_repo) == nil
  end

  test "remove notes repo" do
    %{user: user, repo: repo} = fixtures()

    note_repo = notes_repo_fixture(user, repo)

    assert {:ok, _} = Notes.delete_notes_repo(note_repo)

    assert Notes.get_notes_repo(note_repo.id) == nil
  end

  @valid_file_attrs %{
    file_name: "2020-08-01.md",
    content: "file content"
  }

  test "CRUD files to notes_repo" do
    %{user: user, repo: repo} = fixtures()

    notes_repo = notes_repo_fixture(user, repo)

    assert {:ok, %File{} = file} = Notes.create_file(Map.put(@valid_file_attrs, :notes_repo_id, notes_repo.id))

    assert file.notes_repo_id == notes_repo.id
    assert file.file_name == @valid_file_attrs.file_name
    assert file.content == @valid_file_attrs.content

    assert {:ok, %File{} = file2} = Notes.create_file(Map.put(@valid_file_attrs, :notes_repo_id, notes_repo.id))

    files = Notes.list_files_for_user(user.id)

    assert length(files) == 2
    assert file in files
    assert file2 in files

    assert Notes.get_file(file.id) == file

    assert {:ok, _file} = Notes.delete_file(file)

    assert Notes.get_file(file.id) == nil

    assert {:ok, %File{}} = Notes.update_file(file2, %{"file_name" => "new_file_name.md", "content" => "new content"})

    assert Notes.get_file(file2).content == "new content"
    assert Notes.get_file(file2).file_name == "new_file_name.md"
  end

end
