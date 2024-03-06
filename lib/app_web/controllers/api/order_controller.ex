defmodule AppWeb.API.OrderController do
  use AppWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias App.Orders
  alias AppWeb.API.{Schemas, Utils}

  @result_limit 20

  operation(:index,
    summary: "List orders",
    parameters: [
      status: [in: :query, type: :string, description: "Filter by status"],
      product_id: [in: :query, type: :string, description: "Filter by Product ID"],
      product_variant_id: [in: :query, type: :string, description: "Filter by Product Variant ID"],
      page: [in: :query, type: :integer, description: "Page number"]
    ],
    responses: [
      ok: {"Order list", "application/json", Schemas.OrdersResponse}
    ]
  )

  def index(%{assigns: %{current_user: user}} = conn, params) do
    # this is to support API clients that expect an array e.g Zapier
    as_array = params["as_array"] == "true"

    filters =
      []
      |> Utils.maybe_put_string_filter(params, "status")
      |> Utils.maybe_put_string_filter(params, "product_id")
      |> Utils.maybe_put_string_filter(params, "product_variant_id")

    query = %{
      order_by: [:inserted_at],
      order_directions: [:desc],
      page_size: @result_limit,
      page: Map.get(params, "page", "1"),
      filters: filters
    }

    {orders, meta} = Orders.list_orders!(user, query)
    render(conn, :index, orders: orders, meta: meta, as_array: as_array)
  end

  operation(:show,
    summary: "Show order",
    parameters: [
      id: [in: :path, type: :string, description: "Order ID"]
    ],
    responses: [
      ok: {"Order", "application/json", Schemas.OrderResponse}
    ]
  )

  def show(conn, %{"id" => id}) do
    order = Orders.get_order!(id)
    render(conn, :show, order: order)
  end
end
