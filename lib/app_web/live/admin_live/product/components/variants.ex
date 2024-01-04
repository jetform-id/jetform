defmodule AppWeb.AdminLive.Product.Components.Variants do
  use AppWeb, :live_component
  use AppWeb, :html

  alias App.Products
  alias AppWeb.AdminLive.Product.Components.Commons

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"variant-for-product-" <> @id} class="p-4 md:p-8 dark:bg-gray-800 space-y-4">
      <%!-- variant list --%>
      <div id="variant-list-for-product" class="space-y-4" phx-update="stream">
        <Commons.variant_item
          :for={{dom_id, variant} <- @streams.variants}
          id={dom_id}
          variant={variant}
          on_edit="edit"
          on_delete="delete"
          target={@myself}
        />
      </div>

      <%!-- new variant button --%>
      <.button
        phx-click={JS.push("new", target: @myself)}
        type="button"
        class="mt-2 w-full bg-primary-700 hover:bg-primary-800 text-white border focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-3 text-center me-2 mb-2"
      >
        <.icon name="hero-plus-small w-4 h-4" />Buat Varian Produk
      </.button>

      <%!-- new and edit modal --%>
      <.modal :if={@show_modal} id="variant-modal" show on_cancel={JS.push("cancel", target: @myself)}>
        <Commons.variant_form changeset={@changeset} on_submit="save" target={@myself} />
      </.modal>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> stream(:variants, Products.list_variants_by_product(assigns.product))
      |> assign(:show_modal, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("new", _params, socket) do
    socket =
      socket
      |> assign(:changeset, Products.change_variant(%Products.Variant{}, %{}))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    {:noreply, close_modal(socket)}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    changeset = Products.change_variant(Products.get_variant!(id), %{})

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    variant = Products.get_variant!(id)

    case Products.delete_variant(variant) do
      {:ok, _} ->
        notify_parent()
        {:noreply, stream_delete(socket, :variants, variant)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save", %{"variant" => variant_params}, socket) do
    case socket.assigns.changeset.data.id do
      nil -> create_variant(socket, variant_params)
      _id -> update_variant(socket, socket.assigns.changeset.data, variant_params)
    end
  end

  defp create_variant(socket, params) do
    params = Map.put(params, "product", socket.assigns.product)

    case Products.create_variant(params) do
      {:ok, variant} ->
        notify_parent()

        socket =
          socket
          |> stream_insert(:variants, variant)
          |> close_modal()

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp update_variant(socket, variant, params) do
    case Products.update_variant(variant, params) do
      {:ok, variant} ->
        notify_parent()

        socket =
          socket
          |> stream_insert(:variants, variant)
          |> close_modal()

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp close_modal(socket) do
    socket
    |> assign(:show_modal, false)
    |> assign(:changeset, nil)
  end

  defp notify_parent() do
    send(self(), {__MODULE__, :variants_updated})
  end
end
