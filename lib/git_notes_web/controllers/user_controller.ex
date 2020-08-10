defmodule GitNotesWeb.UserController do
  use GitNotesWeb, :controller

  alias GitNotes.{GitRepos, Accounts, Notes, Github}

  plug :authenticate when action in [:show, :edit, :update]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def show(conn, _params) do
    conn
    |> assign(:repos, GitRepos.list_user_repos(conn.assigns.current_user))
    |> assign(:notes_repo_id, conn.assigns.current_user.notes_repo_id)
    |> render("show.html")
  end

  def edit(conn, _params) do
    conn
    |> assign(:repos, GitRepos.list_user_repos(conn.assigns.current_user))
    |> assign(:changeset, Accounts.change_user(conn.assigns.current_user))
    |> render("edit.html")
  end

  def update(conn, %{"user" => %{"notes_repo_id" => updated_repo_id} = updated_user}) do
    %{current_user: current_user} = conn.assigns
    if current_user.notes_repo_id && current_user.notes_repo_id != Integer.parse(updated_repo_id) do
      Notes.delete_user_files(current_user.id)
    end

    new_user = Accounts.update_user(current_user, updated_user)

    Github.populate_notes(new_user.notes_repo_id)

    redirect(conn, to: Routes.user_path(conn, :show, conn.assigns.current_user.id))
  end


end
