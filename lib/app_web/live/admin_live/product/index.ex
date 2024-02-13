defmodule AppWeb.AdminLive.Product.Index do
  use AppWeb, :live_view
  alias App.Products

  @result_limit 20

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:show_modal, false)
      |> assign(:page_title, "Produk")
      |> stream(:products, [])

    {:ok, socket}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  @impl true
  def handle_event("new", _params, socket) do
    initial_slug = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)

    socket =
      socket
      |> assign(:show_modal, true)
      |> assign(
        :changeset,
        Products.change_product(%Products.Product{}, %{"slug" => initial_slug})
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    socket =
      case Products.get_product(id) do
        nil ->
          socket
          |> put_flash(:error, "Gagal menghapus produk.")

        product ->
          Products.delete_product(product)

          socket
          |> stream_delete(:products, product)
          |> put_flash(:info, "Produk berhasil dihapus.")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    {:noreply, push_patch(socket, to: ~p"/products?page=#{page}", replace: true)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_params(socket, params)}
  end

  defp apply_params(socket, params) do
    query = %{
      order_by: [:inserted_at],
      order_directions: [:desc],
      page_size: @result_limit,
      page: Map.get(params, "page", "1")
    }

    {products, meta} = Products.list_products_by_user!(socket.assigns.current_user, query)

    socket
    |> stream(:products, products, reset: true)
    |> assign(:pagination, meta)
  end
end
