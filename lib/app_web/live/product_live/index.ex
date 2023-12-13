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
  def handle_event("create", %{"product" => product_params}, socket) do
    params = Map.put(product_params, "user", socket.assigns.current_user)

    socket =
      case Products.create_product(params) do
        {:ok, product} ->
          socket
          |> put_flash(:info, "Product created successfully.")
          |> push_navigate(to: ~p"/admin/products/#{product.id}/edit")

        {:error, changeset} ->
          socket
          |> assign(:changeset, changeset)
      end

    {:noreply, socket}
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
    socket
    |> assign(:new_modal, true)
    |> assign(:page_title, "New Product")
    |> assign(:changeset, Products.change_product(%Products.Product{}, %{}))
    |> assign(:action, ~p"/admin/products")
  end

  defp apply_params(socket, _params) do
    socket
    |> assign(:new_modal, false)
    |> assign(:page_title, "Products")
  end
end
