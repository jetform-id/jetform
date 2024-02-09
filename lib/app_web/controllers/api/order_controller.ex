defmodule AppWeb.API.OrderController do
  use AppWeb, :controller
  alias App.Orders

  @result_limit 10

  def index(%{assigns: %{current_user: user}} = conn, params) do
    filters =
      []
      |> maybe_put_filter(params, "status")
      |> maybe_put_filter(params, "product_id")
      |> maybe_put_filter(params, "product_variant_id")

    query = %{
      order_by: [:inserted_at],
      order_directions: [:desc],
      page_size: @result_limit,
      page: Map.get(params, "page", "1"),
      filters: filters
    }

    {orders, meta} = Orders.list_orders!(user, query)
    render(conn, :index, orders: orders, meta: meta)
  end

  def show(conn, %{"id" => id}) do
    order = Orders.get_order!(id)
    render(conn, :show, order: order)
  end

  defp maybe_put_filter(filters, params, filter, op \\ :==) do
    case Map.get(params, filter) do
      nil -> filters
      value -> [%{field: String.to_atom(filter), op: op, value: value} | filters]
    end
  end
end
