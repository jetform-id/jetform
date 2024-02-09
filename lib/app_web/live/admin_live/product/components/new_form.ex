defmodule AppWeb.AdminLive.Product.Components.NewForm do
  use AppWeb, :live_component

  alias App.Products

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form
        :let={f}
        for={@changeset}
        as={:product}
        phx-update="replace"
        phx-change="validate"
        phx-submit="create"
        phx-target={@myself}
      >
        <div class="mt-8 space-y-6">
          <.input field={f[:name]} type="text" label="Nama Produk" required />
          <.input field={f[:slug]} type="hidden" required />
          <.input field={f[:price]} type="number" label="Harga" required>
            <:help>
              <div class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                Masukkan 0 untuk membuat produk ini gratis.
              </div>
            </:help>
          </.input>
        </div>

        <:actions>
          <div class="mt-8">
            <.button
              phx-disable-with="Creating..."
              class="w-full px-5 py-3 text-base font-medium text-center text-white bg-primary-700 rounded-lg hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 sm:w-auto dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
            >
              Buat Produk <span aria-hidden="true">→</span>
            </.button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def handle_event("create", %{"product" => product_params}, socket) do
    params = Map.put(product_params, "user", socket.assigns.current_user)

    socket =
      case Products.create_product(params) do
        {:ok, product} ->
          socket
          |> put_flash(:info, "Produk berhasil dibuat.")
          |> push_navigate(to: ~p"/admin/products/#{product.id}/edit")

        {:error, changeset} ->
          socket
          |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      Products.change_product(%Products.Product{}, product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end
end
