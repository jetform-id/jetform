defmodule AppWeb.PageController do
  use AppWeb, :controller
  alias App.Orders

  def index(conn, _params) do
    render(conn, :index)
  end

  def thanks(conn, %{"id" => id}) do
    order = Orders.get_order!(id)

    case order.status in [:free, :paid] do
      true ->
        conn
        |> assign(:page_title, "Terima kasih!")
        |> assign(:order, order)
        |> render(:thanks)

      _ ->
        redirect(conn, to: ~p"/invoices/#{order.id}")
    end
  end
end
