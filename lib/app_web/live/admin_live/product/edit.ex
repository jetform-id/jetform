defmodule AppWeb.AdminLive.Product.Edit do
  use AppWeb, :live_view
  alias App.Products
  alias AppWeb.AdminLive.Product.Components.{EditForm, Preview}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    product = Products.get_product!(id) |> App.Repo.preload(:user)

    socket =
      socket
      |> assign(:page_title, "Edit: #{product.name}")
      |> assign(:product, product)
      |> assign(:changeset, Products.change_product(product, %{}))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    # set details changes
    # TODO: handle details on client side
    product_params =
      case Map.get(socket.assigns.changeset.changes, :details) do
        nil -> product_params
        details -> Map.put(product_params, "details", details)
      end

    changeset =
      socket.assigns.product
      |> Products.change_product(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"product" => product_params}, socket) do
    # set details changes
    # TODO: handle details on client side
    product_params =
      case Map.get(socket.assigns.changeset.changes, :details) do
        nil -> product_params
        details -> Map.put(product_params, "details", details)
      end

    socket =
      case Products.update_product(socket.assigns.product, product_params) do
        {:ok, product} ->
          socket
          |> assign(:product, product)
          |> assign(:changeset, Products.change_product(product, %{}))
          |> put_flash(:info, "Produk berhasil disimpan.")
          |> redirect(to: ~p"/products/#{product.id}/stats")

        {:error, changeset} ->
          socket
          |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_detail", _params, socket) do
    {:noreply,
     assign(
       socket,
       :changeset,
       Products.add_detail(socket.assigns.product, socket.assigns.changeset)
     )}
  end

  @impl true
  def handle_event("delete_detail", detail, socket) do
    {:noreply,
     assign(
       socket,
       :changeset,
       Products.delete_detail(socket.assigns.product, socket.assigns.changeset, detail)
     )}
  end

  @impl true
  def handle_event(
        "update_detail",
        %{"_target" => [target]} = params,
        socket
      ) do
    ["detail", type, id] = String.split(target, "_")

    changeset =
      Products.update_detail(
        socket.assigns.product,
        socket.assigns.changeset,
        id,
        type,
        params[target]
      )

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_params(%{"tab" => tab}, _uri, socket) do
    {:noreply, assign(socket, :tab, tab)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, :tab, "details")}
  end

  # handle messages from child components
  @impl true
  def handle_info({:flash, :clear}, socket) do
    {:noreply, clear_flash(socket)}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def handle_info(:images_updated, socket) do
    {:noreply, update_preview(socket)}
  end

  @impl true
  def handle_info(:variants_updated, socket) do
    {:noreply, update_preview(socket)}
  end

  defp update_preview(socket) do
    product = socket.assigns.product
    send_update(Preview, id: product.id, product: product)
    socket
  end
end
