defmodule AppWeb.Router do
  use AppWeb, :router
  use Pow.Phoenix.Router

  use Pow.Extension.Phoenix.Router,
    extensions: [PowResetPassword, PowEmailConfirmation]

  # -------------------- Pipelines --------------------
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AppWeb.Plug.Globals
  end

  pipeline :auth_area do
    plug :put_layout, html: {AppWeb.Layouts, :auth}
  end

  pipeline :admin_area do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: AppWeb.PowAuthErrorHandler

    plug :put_layout, html: {AppWeb.Layouts, :admin}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :protected_api do
    plug :accepts, ["json"]
    plug AppWeb.Plug.RequireAPIKey
  end

  # -------------------- Scopes --------------------
  scope "/api", AppWeb do
    pipe_through :api

    get "/payment/redirect", PaymentController, :midtrans_redirect
    post "/payment/notification", PaymentController, :midtrans_notification

    scope "/v1" do
      pipe_through :protected_api
      resources "/orders", API.OrderController, only: [:index, :show]
    end
  end

  scope "/", AppWeb do
    pipe_through [:browser]

    # public pages
    get "/access/:id", AccessController, :index

    # public live-pages
    live_session :public,
      on_mount: {AppWeb.LiveAuth, :default},
      layout: {AppWeb.Layouts, :checkout} do
      live "/p/:slug", PublicLive.Checkout
      live "/invoice/:id", PublicLive.Invoice
    end
  end

  scope "/" do
    pipe_through [:browser, :auth_area]

    # authentication
    pow_routes()
    pow_extension_routes()
  end

  scope "/", AppWeb do
    pipe_through [:browser, :admin_area]

    # accounts
    get "/account", AccountController, :edit
    put "/account", AccountController, :update
    post "/account", AccountController, :update

    live_session :admin, on_mount: {AppWeb.LiveAuth, :admin}, layout: {AppWeb.Layouts, :admin} do
      # products
      live "/products", AdminLive.Product.Index
      live "/products/:id/edit", AdminLive.Product.Edit

      # withdrawals
      live "/withdrawals", AdminLive.Withdrawal.Index
      live "/withdrawals/confirm/:token", AdminLive.Withdrawal.Index, :confirm

      # integrations
      live "/integrations", AdminLive.APIKey.Index

      # dashboard
      live "/", AdminLive.Dashboard.Index
    end
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
