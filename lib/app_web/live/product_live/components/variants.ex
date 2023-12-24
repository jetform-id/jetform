defmodule AppWeb.ProductLive.Components.Variants do
  use AppWeb, :live_component
  use AppWeb, :html

  alias App.Products

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"product-" <> @id} class="p-4 md:p-8 dark:bg-gray-800 space-y-4">
      <%!-- variant list --%>
      <div :for={variant <- @product.variants} class="w-full bg-gray-50 shadow-sm rounded-lg border border-gray-300 p-4">
        <div class="flex mb-4 items-center">
          <span class="flex-1 font-semibold">
            <%= variant.name %> - Rp. <.price value={variant.price} />
          </span>
          <span class="flex-none items-center">
            <.button
              phx-click={JS.push("edit", value: %{id: variant.id}, target: @myself)}
              type="button"
              class="text-primary-700 hover:text-white border border-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-2 py-1 text-center dark:border-primary-500 dark:text-primary-500 dark:hover:text-white dark:hover:bg-primary-500 dark:focus:ring-primary-800"
            >
              Edit
            </.button>
            <.button
              phx-click={JS.push("delete", value: %{id: variant.id}, target: @myself)}
              type="button"
              class="text-red-600 hover:text-white border border-red-600 hover:bg-red-600 focus:ring-4 focus:outline-none focus:ring-red-300 font-medium rounded-lg text-sm px-2 py-1 text-center dark:border-red-600 dark:text-red-500 dark:hover:text-white dark:hover:bg-red-500 dark:focus:ring-red-600"
            >
              <.icon name="hero-trash w-4 h-4" />
            </.button>
          </span>
        </div>
        <p class="text-slate-600 text-sm text-sm mt-1 pr-4">
          <%= variant.description %>
        </p>
        <%!-- <div :if={variant.quantity} class="pt-2">
          <span class="bg-yellow-100 text-yellow-800 text-xs font-medium inline-flex items-center px-2 py-0.5 rounded dark:bg-gray-700 dark:text-yellow-400 border border-yellow-400">
            <.icon name="hero-clock w-3 h-3 me-1" /> Sisa <%= variant.quantity %>
          </span>
        </div> --%>
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
      <.modal :if={@show_modal} id="detail-modal" show on_cancel={JS.push("cancel", target: @myself)}>
        <.variant_form changeset={@changeset} target={@myself} />
      </.modal>
    </div>
    """
  end

  attr :changeset, :map, required: true
  attr :target, :any, required: true

  def variant_form(assigns) do
    assigns =
      case assigns.changeset.data.id do
        nil ->
          assigns
          |> assign(:action, "create")
          |> assign(:title, "New Variant")
          |> assign(:btn_text, "Create")
          |> assign(:loading_text, "Creating...")

        _ ->
          assigns
          |> assign(:action, "update")
          |> assign(:title, "Edit Variant")
          |> assign(:btn_text, "Update")
          |> assign(:loading_text, "Updating...")
      end

    ~H"""
    <.simple_form
      :let={f}
      for={@changeset}
      as={:variant}
      phx-update="replace"
      phx-submit={@action}
      phx-target={@target}
    >
      <div class="mt-8 space-y-6">
        <div class="grid grid-cols-2 gap-4">
          <.input field={f[:name]} type="text" label="Nama varian" required />
          <.input field={f[:price]} type="number" label="Harga" required>
            <:help>
              <div class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                Masukkan 0 untuk membuat varian ini gratis.
              </div>
            </:help>
          </.input>
        </div>
        <.input field={f[:description]} type="textarea" label="Keterangan" required />

        <%!-- variant settings --%>
        <%!-- <hr class="h-px my-8 bg-gray-200 border-0 dark:bg-gray-700" />
        <div class="flex">
          <div class="flex items-center h-5">
            <input
              id="helper-checkbox"
              aria-describedby="helper-checkbox-text"
              type="checkbox"
              value=""
              class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
            />
          </div>
          <div class="ms-2 text-sm">
            <label for="helper-checkbox" class="font-medium text-gray-900 dark:text-gray-300">
              Batasi jumlah pembelian
            </label>
            <p id="helper-checkbox-text" class="text-xs font-normal text-gray-500 dark:text-gray-300">
              Produk hanya bisa dibeli ketika jumlah pembelian belum mencapai batas tertentu.
            </p>
            <.input field={f[:quantity]} type="number" label="Quantity" />
          </div>
        </div>

        <div class="flex">
          <div class="flex items-center h-5">
            <input
              id="helper-checkbox"
              aria-describedby="helper-checkbox-text"
              type="checkbox"
              value=""
              class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
            />
          </div>
          <div class="ms-2 text-sm">
            <label for="helper-checkbox" class="font-medium text-gray-900 dark:text-gray-300">
              Batasi waktu pembelian
            </label>
            <p id="helper-checkbox-text" class="text-xs font-normal text-gray-500 dark:text-gray-300">
              Produk hanya bisa dibeli sampai tanggal tertentu.
            </p>
          </div>
        </div> --%>
      </div>

      <:actions>
        <div class="mt-8">
          <.button
            phx-disable-with={@loading_text}
            class="w-full px-5 py-3 text-base font-medium text-center text-white bg-primary-700 rounded-lg hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 sm:w-auto dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
          >
            <%= @btn_text %>
            <span aria-hidden="true">→</span>
          </.button>
        </div>
      </:actions>
    </.simple_form>
    """
  end

  @impl true
  def update(assigns, socket) do
    product = assigns.product
    variants = product.variants |> Enum.sort_by(& &1.inserted_at, :asc)

    socket =
      socket
      |> assign(assigns)
      |> assign(:product, product |> Map.put(:variants, variants))
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
    socket =
      socket
      |> assign(:show_modal, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create", %{"variant" => variant_params}, socket) do
    params = Map.put(variant_params, "product", socket.assigns.product)

    case Products.create_variant(params) do
      {:ok, variant} ->
        notify_parent(:create, variant)

        socket =
          socket
          |> assign(:show_modal, false)
          |> assign(:changeset_id, nil)
          |> assign(:changeset, nil)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("update", %{"variant" => variant_params}, socket) do
    with %{} = variant <- Products.get_variant(socket.assigns.changeset_id),
         {:ok, variant} <- Products.update_variant(variant, variant_params) do
      notify_parent(:update, variant)

      socket =
        socket
        |> assign(:show_modal, false)
        |> assign(:changeset_id, nil)
        |> assign(:changeset, nil)

      {:noreply, socket}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    changeset = Products.get_variant(id) |> Products.change_variant(%{})

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:changeset_id, id)
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    variant = Products.get_variant(id)
    Products.delete_variant(variant)
    notify_parent(:delete, variant)
    {:noreply, socket}
  end

  defp notify_parent(event, variant) do
    send(self(), {__MODULE__, event, variant})
  end
end
