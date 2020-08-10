defmodule GitNotesWeb.Router do
  use GitNotesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {GitNotesWeb.LayoutView, :root}
    plug GitNotesWeb.Auth
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GitNotesWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/users/install", UserController, :install
    resources "/users", UserController, only: [:new, :show, :edit, :update]
    resources "/sessions", SessionController, only: [:new, :delete]
  end


  scope "/notes", GitNotesWeb do
    pipe_through [:browser, :authenticate]
    live "/", NotesLive
  end

  scope "/webhooks", GitNotesWeb do
    pipe_through [:api, :verify_signature]
    post "/", WebhookController, :webhook
  end
  # Other scopes may use custom stacks.
  # scope "/api", GitNotesWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/", GitNotesWeb do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: GitNotesWeb.Telemetry
    end
  end

end
