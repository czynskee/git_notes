defmodule GitNotes.NotesTest do
  use GitNotes.DataCase, async: true

  alias GitNotes.{Notes, Accounts}
  alias GitNotes.Notes.{File, Topic, TopicEntry}

  @content """
# Books
Drive

# Invest
ASML
AMAT
ARMH
SWX: COTN

""" |> Base.encode64()

  test "create a file" do
    user = %GitNotes.Accounts.User{
      access_token: "5d632d83dffc05f33a90b07314b67413350e48eb",
      access_token_expiration: ~U[2020-08-15 06:06:43Z],
      id: 8753265,
      inserted_at: ~N[2020-08-14 22:04:39],
      installation_access_token: "v1.dfbbe00681fa321a1e35d640ed5051507335cbd1",
      installation_access_token_expiration: ~U[2020-08-14 23:04:39Z],
      installation_id: 11255150,
      login: "czynskee",
      refresh_token: "r1.9c7003462e70c24c5fab875b5a1e1923a67d9d2374ff5ff08f8efdfb35397075c060873cb3e2208d",
      refresh_token_expiration: ~U[2021-02-14 22:06:42Z],
      updated_at: ~N[2020-08-14 22:07:10],
    } |> GitNotes.Repo.insert!()

    repo = %GitNotes.GitRepos.GitRepo{
      id: 278936393,
      inserted_at: ~N[2020-08-14 22:04:39],
      name: "notes",
      private: true,
      updated_at: ~N[2020-08-14 22:04:39],
      user_id: 8753265
    } |> GitNotes.Repo.insert!()

    GitNotes.Accounts.update_user(user, %{notes_repo_id: 278936393})

    file = %{
      "content" => @content,
      "name" => "2020-08-13.md",
      "git_repo_id" => repo.id
    } 

    # entries = File.find_topic_entries(@content)
    
    # Notes.create_topics_from_entries(entries, user.id, Date.utc_today())
    
    Notes.change_file(%File{}, file)
    |> Map.get(:changes)
    |> Map.get(:topic_entries)
    |> Enum.at(0)
    |> Map.get(:data)
    |> Map.get(:content)
    |> Base.decode64()
    |> IO.inspect

  end


end















  # @valid_attrs %{
  #   "name" => "2020-07-15.md",
  #   "content" => "files contents",
  #   "git_repo_id" => 12345
  # }

  # @invalid_attrs %{
  #   "name" => "something.md",
  #   "content" => "  ",
  #   "git_repo_id" => 12345
  # }

  # setup do
  #   fixtures = fixtures()

  #   {:ok, fixtures: fixtures}
  # end


  # test "CRUD file" do
  #   assert %File{} = file = Notes.create_file(@valid_attrs)
  #   assert catch_error Notes.create_file(@invalid_attrs)
  #   assert catch_error Notes.create_file(%{@invalid_attrs | "name" => "2020-13-04.md"})

  #   assert file.name == @valid_attrs["name"]
  #   assert file.content == @valid_attrs["content"]
  #   assert file.git_repo_id == @valid_attrs["git_repo_id"]

  #   new_file = Notes.update_file(file, %{"content" => "some new content"})

  #   assert new_file.content == "some new content"

  #   Notes.delete_file(file)
  #   assert Notes.get_file(file) == nil
  # end

  # test "cannot have two files with the same name for the same repo id" do
  #   %File{} = Notes.create_file(@valid_attrs)
  #   assert catch_error Notes.create_file(@valid_attrs)

  #   # but we should have no issue if the repo id's are different

  #   user = user_fixture(%{"id" => 9999, "login" => "panda", "installation_id" => 9999})
  #   repo = repo_fixture(%{"user_id" => user.id, "id" => 9999})

  #   %File{} = Notes.create_file(%{@valid_attrs | "git_repo_id" => repo.id})
  # end

  # test "delete user files", %{fixtures: fixtures} do
  #   Notes.create_file(@valid_attrs)
  #   Notes.create_file(%{@valid_attrs | "name" => "2020-07-14.md"})

  #   other_user = user_fixture(%{"id" => 000, "installation_id" => 111, "login" => "other"})
  #   other_repo = repo_fixture(%{"id" => 999, "user_id" => other_user.id})
  #   Accounts.update_user(other_user, %{"notes_repo_id" => other_repo.id})
  #   Notes.create_file(%{@valid_attrs | "git_repo_id" => other_repo.id})

  #   Notes.list_user_files(other_user.id)

  #   Notes.delete_user_files(fixtures.user.id)

  #   assert length(Notes.list_user_files(fixtures.user.id)) == 0

  #   assert length(Notes.list_user_files(other_user.id)) == 1
  # end



  # describe "topics" do
  #   alias GitNotes.Notes.Topic

  #   @valid_attrs %{name: "some name", file_id: 88888}
  #   @update_attrs %{name: "some updated name"}
  #   @invalid_attrs %{name: nil}

  #   def topic_fixture(attrs \\ %{}) do
  #     {:ok, topic} =
  #       attrs
  #       |> Enum.into(@valid_attrs)
  #       |> Notes.create_topic()

  #     topic
  #   end

  #   setup do
  #     Notes.create_file(@valid_attrs)
  #   end

  #   test "list_topics/0 returns all topics" do
  #     topic = topic_fixture()
  #     assert Notes.list_topics() == [topic]
  #   end

  #   test "get_topic!/1 returns the topic with given id" do
  #     topic = topic_fixture()
  #     assert Notes.get_topic!(topic.id) == topic
  #   end

  #   test "create_topic/1 with valid data creates a topic" do
  #     assert {:ok, %Topic{} = topic} = Notes.create_topic(@valid_attrs)
  #     assert topic.name == "some name"
  #   end

  #   test "create_topic/1 with invalid data returns error changeset" do
  #     assert {:error, %Ecto.Changeset{}} = Notes.create_topic(@invalid_attrs)
  #   end

  #   test "update_topic/2 with valid data updates the topic" do
  #     topic = topic_fixture()
  #     assert {:ok, %Topic{} = topic} = Notes.update_topic(topic, @update_attrs)
  #     assert topic.name == "some updated name"
  #   end

  #   test "update_topic/2 with invalid data returns error changeset" do
  #     topic = topic_fixture()
  #     assert {:error, %Ecto.Changeset{}} = Notes.update_topic(topic, @invalid_attrs)
  #     assert topic == Notes.get_topic!(topic.id)
  #   end

  #   test "delete_topic/1 deletes the topic" do
  #     topic = topic_fixture()
  #     assert {:ok, %Topic{}} = Notes.delete_topic(topic)
  #     assert_raise Ecto.NoResultsError, fn -> Notes.get_topic!(topic.id) end
  #   end

  #   test "change_topic/1 returns a topic changeset" do
  #     topic = topic_fixture()
  #     assert %Ecto.Changeset{} = Notes.change_topic(topic)
  #   end
  # end

#   describe "topic_entries" do
#     alias GitNotes.Notes.TopicEntry

#     @valid_attrs %{content: "some content"}
#     @update_attrs %{content: "some updated content"}
#     @invalid_attrs %{content: nil}

#     def topic_entry_fixture(attrs \\ %{}) do
#       {:ok, topic_entry} =
#         attrs
#         |> Enum.into(@valid_attrs)
#         |> Notes.create_topic_entry()

#       topic_entry
#     end

#     test "list_topic_entries/0 returns all topic_entries" do
#       topic_entry = topic_entry_fixture()
#       assert Notes.list_topic_entries() == [topic_entry]
#     end

#     test "get_topic_entry!/1 returns the topic_entry with given id" do
#       topic_entry = topic_entry_fixture()
#       assert Notes.get_topic_entry!(topic_entry.id) == topic_entry
#     end

#     test "create_topic_entry/1 with valid data creates a topic_entry" do
#       assert {:ok, %TopicEntry{} = topic_entry} = Notes.create_topic_entry(@valid_attrs)
#       assert topic_entry.content == "some content"
#     end

#     test "create_topic_entry/1 with invalid data returns error changeset" do
#       assert {:error, %Ecto.Changeset{}} = Notes.create_topic_entry(@invalid_attrs)
#     end

#     test "update_topic_entry/2 with valid data updates the topic_entry" do
#       topic_entry = topic_entry_fixture()
#       assert {:ok, %TopicEntry{} = topic_entry} = Notes.update_topic_entry(topic_entry, @update_attrs)
#       assert topic_entry.content == "some updated content"
#     end

#     test "update_topic_entry/2 with invalid data returns error changeset" do
#       topic_entry = topic_entry_fixture()
#       assert {:error, %Ecto.Changeset{}} = Notes.update_topic_entry(topic_entry, @invalid_attrs)
#       assert topic_entry == Notes.get_topic_entry!(topic_entry.id)
#     end

#     test "delete_topic_entry/1 deletes the topic_entry" do
#       topic_entry = topic_entry_fixture()
#       assert {:ok, %TopicEntry{}} = Notes.delete_topic_entry(topic_entry)
#       assert_raise Ecto.NoResultsError, fn -> Notes.get_topic_entry!(topic_entry.id) end
#     end

#     test "change_topic_entry/1 returns a topic_entry changeset" do
#       topic_entry = topic_entry_fixture()
#       assert %Ecto.Changeset{} = Notes.change_topic_entry(topic_entry)
#     end
#   end
# end
