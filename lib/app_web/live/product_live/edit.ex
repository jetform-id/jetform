defmodule AppWeb.ProductLive.Edit do
  use AppWeb, :live_view
  alias App.Products

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    socket =
      case Products.get_product(id) do
        nil ->
          socket
          |> put_flash(:error, "Product not found.")
          |> redirect(to: ~p"/admin/products")

        product ->
          changeset = Products.change_product(product, %{})

          socket
          |> assign(:page_title, "Edit: #{product.name}")
          |> assign(:product, product)
          |> assign(:changeset, changeset)
          |> assign(:action, ~p"/admin/products")
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.product
      |> Products.change_product(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"product" => product_params}, socket) do
    socket =
      case Products.update_product(socket.assigns.product, product_params) do
        {:ok, product} ->
          socket
          |> assign(:product, product)
          |> assign(:changeset, Products.change_product(product, %{}))
          |> put_flash(:info, "Product updated successfully.")
          |> push_navigate(to: ~p"/admin/products")

        {:error, changeset} ->
          socket
          |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end
end
