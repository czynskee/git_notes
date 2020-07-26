defmodule GitNotesWeb.UserViewTest do
  use GitNotesWeb.ConnCase, async: true
  alias GitNotesWeb.UserView
  @app_name Application.fetch_env!(:git_notes, :public_app_name)

  test "retrieve the app name correctly" do
    assert UserView.get_app_name() == @app_name
  end
end
