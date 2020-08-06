defmodule GitNotes.NotesTest do
  use GitNotes.DataCase, async: true

  alias GitNotes.Notes
  alias GitNotes.Notes.File

  @valid_attrs %{
    "name" => "2020-07-15.md",
    "content" => "files contents",
    "git_repo_id" => 12345
  }

  @invalid_attrs %{
    "name" => "something.md",
    "content" => "  ",
    "git_repo_id" => 12345
  }

  setup do
    fixtures()

    :ok
  end

  test "CRUD file" do
    assert %File{} = file = Notes.create_file(@valid_attrs)
    assert catch_error Notes.create_file(@invalid_attrs)
    assert catch_error Notes.create_file(%{@invalid_attrs | "name" => "2020-13-04.md"})

    assert file.name == @valid_attrs["name"]
    assert file.content == @valid_attrs["content"]
    assert file.git_repo_id == @valid_attrs["git_repo_id"]

    new_file = Notes.update_file(file, %{"content" => "some new content"})

    assert new_file.content == "some new content"

    Notes.delete_file(file)
    assert Notes.get_file(file) == nil
  end

  test "cannot have two files with the same name for the same repo id" do
    %File{} = Notes.create_file(@valid_attrs)
    assert catch_error Notes.create_file(@valid_attrs)

    # but we should have no issue if the repo id's are different

    user = user_fixture(%{"id" => 9999, "login" => "panda", "installation_id" => 9999})
    repo = repo_fixture(%{"user_id" => user.id, "id" => 9999})

    %File{} = Notes.create_file(%{@valid_attrs | "git_repo_id" => repo.id})
  end


end
