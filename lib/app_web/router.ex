defmodule AppWeb.Router do
  use AppWeb, :router
  use Pow.Phoenix.Router

  use Pow.Extension.Phoenix.Router,
    extensions: [PowResetPassword, PowEmailConfirmation]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :auth_area do
    plug :put_layout, html: {AppWeb.Layouts, :auth}
  end

  pipeline :admin_area do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: AppWeb.AuthErrorHandler

    plug AppWeb.Plug.AdminMenus

    plug :put_layout, html: {AppWeb.Layouts, :admin}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through [:browser, :auth_area]

    pow_routes()
    pow_extension_routes()
  end

  scope "/", AppWeb do
    pipe_through [:browser, :admin_area]
    # accounts
    get "/account", AccountController, :edit
    put "/account", AccountController, :update

    # products
    get "/products", ProductController, :index
    get "/products/new", ProductController, :new
    get "/products/:id/edit", ProductController, :edit
    post "/products", ProductController, :create
    put "/products/:id", ProductController, :update
    delete "/products/:id", ProductController, :delete

    # payouts
    get "/payouts/bank-account", PayoutController, :edit_bank_account
    post "/payouts/bank-account", PayoutController, :create_or_update_bank_account
    put "/payouts/bank-account", PayoutController, :create_or_update_bank_account

    # dashboard
    get "/", AdminController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", AppWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:app, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AppWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
