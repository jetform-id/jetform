defmodule AppWeb.StorefrontController do
  use AppWeb, :controller

  plug :put_layout, html: {AppWeb.Layouts, :checkout}

  def index(conn, _params) do
    render(conn, :index)
  end
end
