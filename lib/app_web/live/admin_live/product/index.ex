defmodule AppWeb.AdminLive.Product.Index do
  use AppWeb, :live_view
  alias App.Products

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :products, Products.list_products_by_user(socket.assigns.current_user))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_params(socket, params)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    socket =
      case Products.get_product(id) do
        nil ->
          socket
          |> put_flash(:error, "Product not found.")

        product ->
          Products.delete_product(product)

          socket
          |> stream_delete(:products, product)
          |> put_flash(:info, "Product deleted successfully.")
      end

    {:noreply, socket}
  end

  defp apply_params(socket, %{"action" => "new"}) do
    initial_slug = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)

    socket
    |> assign(:new_modal, true)
    |> assign(:page_title, "Buat Produk")
    |> assign(:changeset, Products.change_product(%Products.Product{}, %{"slug" => initial_slug}))
    |> assign(:action, ~p"/admin/products")
  end

  defp apply_params(socket, _params) do
    socket
    |> assign(:new_modal, false)
    |> assign(:page_title, "Produk")
  end
end
