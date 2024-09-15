defmodule AppWeb.Subdomain.Router do
  use AppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AppWeb.Layouts, :root}
    plug :put_layout, html: {AppWeb.Layouts, :storefront}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug AppWeb.Plugs.PutTenant
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AppWeb.Subdomain do
    pipe_through :browser

    live_session :public,
      on_mount: {AppWeb.Subdomain.LiveContext, :default},
      layout: {AppWeb.Layouts, :checkout} do
      live "/:slug", Live.Checkout
    end

    get "/", PageController, :index
  end
end
