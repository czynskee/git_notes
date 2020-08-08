defmodule GitNotes.AccountsTest do
  use GitNotes.DataCase, async: true

  alias GitNotes.Accounts
  alias GitNotes.Accounts.User

  @valid_attrs %{
    id: 12345,
    installation_id: 123,
    login: "czynskee"
  }

  @invalid_attrs %{}

  test "with valid data inserts user" do
    assert %User{id: id} = user = Accounts.register_user(@valid_attrs)

    assert user.installation_id == 123
    assert user.id == 12345
    assert user.login == "czynskee"

    assert [%User{id: ^id}] = Accounts.list_users()
  end

  test "with invalid data returns error" do
    assert catch_error Accounts.register_user(@invalid_attrs)
  end

  test "delete user" do
    user = user_fixture()

    Accounts.delete_user(user)

    assert Accounts.get_user(user.id) == nil
  end

  test "CRUD notes_repo on user" do
    user = user_fixture()
    repo = repo_fixture()
    assert %User{notes_repo_id: notes_repo_id} = Accounts.update_user(user, %{"notes_repo_id" => repo.id})

    assert notes_repo_id == repo.id

    GitNotes.GitRepos.delete_repo(repo)

    assert Accounts.get_user(user).notes_repo_id == nil

    assert catch_error Accounts.update_user(user, %{"notes_repo_id" => repo.id})
  end

  test "update user github credentials" do
    user = user_fixture()
    creds = github_oauth_credentials()
    Accounts.update_github_credentials(user, creds)

    user = Accounts.get_user(user.id)

    assert user.refresh_token == creds["refresh_token"]
    assert user.access_token == creds["access_token"]
    assert_in_delta user.refresh_token_expiration |> DateTime.to_unix(),
      now_plus_seconds(creds["refresh_token_expires_in"]), 5

    assert_in_delta user.access_token_expiration |> DateTime.to_unix(),
      now_plus_seconds(creds["expires_in"]), 5


    end

  describe "ensuring database integrity on subsequent user registrations" do

    setup do
      Accounts.register_user(@valid_attrs)

      :ok
    end

    test "user uniqueness constraints are respected" do
      assert catch_error Accounts.register_user(%{id: 9999, installation_id: 123, login: "someoneelse"})
      assert catch_error Accounts.register_user(%{id: 12345, installation_id: 9999, login: "someoneelse"})
      assert catch_error Accounts.register_user(%{id: 9999, installation_id: 9999, login: "czynskee" })
    end
  end



end
