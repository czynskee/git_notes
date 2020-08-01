defmodule GitNotes.AccountsTest do
  use GitNotes.DataCase, async: true

  alias GitNotes.Accounts
  alias GitNotes.Accounts.User

  @valid_attrs %{
    installation_id: 123,
    id: 12345,
    login: "czynskee"
  }

  @invalid_attrs %{}

  test "with valid data inserts user" do
    assert {:ok, %User{id: id} = user} = Accounts.register_user(@valid_attrs)

    assert user.installation_id == 123
    assert user.id == 12345
    assert user.login == "czynskee"

    assert [%User{id: ^id}] = Accounts.list_users()
  end

  test "with invalid data returns error" do
    assert {:error, reason} = Accounts.register_user(@invalid_attrs)
  end

  test "delete user" do
    user = user_fixture()

    Accounts.delete_user(user)

    assert Accounts.get_user(user.id) == nil
  end
end
