defmodule AppWeb.ProductLive.Index do
  use AppWeb, :live_view
  alias App.Products

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :products, Products.list_products_by_user(socket.assigns.current_user))}
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
          |> redirect(to: ~p"/admin/products")

        product ->
          Products.delete_product(product)

          socket
          |> put_flash(:info, "Product deleted successfully.")
          |> redirect(to: ~p"/admin/products")
      end

    {:noreply, socket}
  end

  defp apply_params(socket, %{"action" => "new"}) do
    initial_slug = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)

    socket
    |> assign(:new_modal, true)
    |> assign(:page_title, "New Product")
    |> assign(:changeset, Products.change_product(%Products.Product{}, %{"slug" => initial_slug}))
    |> assign(:action, ~p"/admin/products")
  end

  defp apply_params(socket, _params) do
    socket
    |> assign(:new_modal, false)
    |> assign(:page_title, "Products")
  end
end
