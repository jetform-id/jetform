defmodule AppWeb.PageController do
  use AppWeb, :controller

  alias App.Users
  alias App.Orders
  alias App.Products.ThanksPageConfig

  def index(conn, _params) do
    render(conn, :index)
  end

  def thanks(conn, %{"id" => id}) do
    order = Orders.get_order!(id) |> App.Repo.preload(:user)
    thanks_config = ThanksPageConfig.get_or_default(order)

    case order.status in [:free, :paid] do
      true ->
        rendered_config = ThanksPageConfig.render(thanks_config, order)

        if thanks_config.type == "redirect" do
          redirect(conn, external: rendered_config.redirect_url)
        else
          conn
          |> assign(:page_title, rendered_config.title)
          |> assign(:order, order)
          |> assign(:config, thanks_config)
          |> assign(:brand_info, Users.get_brand_info(order.user))
          |> render(:thanks)
        end

      _ ->
        redirect(conn, to: ~p"/invoices/#{order.id}")
    end
  end
end
