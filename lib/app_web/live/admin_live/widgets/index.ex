defmodule AppWeb.AdminLive.Widgets.Index do
  use AppWeb, :live_view
  require Logger

  alias App.Products

  @impl true
  def mount(_params, _session, socket) do
    query = %{
      order_by: [:inserted_at],
      order_directions: [:desc],
      filters: [%{field: :is_live, op: :==, value: true}]
    }

    {products, _} = Products.list_products_by_user!(socket.assigns.current_user, query)

    socket =
      socket
      |> assign(:page_title, "Widgets")
      |> assign(:products, [{"Produk...", ""} | Enum.map(products, fn p -> {p.name, p.id} end)])
      |> assign(:selected_product_id, nil)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_product", %{"product" => product_id}, socket) do
    case product_id do
      "" ->
        {:noreply, socket |> assign(:selected_product_id, nil)}

      _ ->
        {:noreply, assign(socket, :selected_product_id, product_id)}
    end
  end
end
