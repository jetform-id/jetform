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
          <.input
            field={f[:price_type]}
            options={App.Products.price_type_options()}
            type="select"
            label="Tipe harga"
            required
          />
          <.input
            :if={show_price_input?(@changeset)}
            field={f[:price]}
            type="number"
            label={
              if Ecto.Changeset.get_field(@changeset, :price_type) == :flexible,
                do: "Harga minimum",
                else: "Harga"
            }
            required
          >
            <:help>
              <div class="pt-3 text-xs text-yellow-500 leading-tight">
              <.icon name="hero-exclamation-circle w-4 h-4" /> Beberapa bank menetapkan nilai minimal transaksi sebesar <.price value={Application.get_env(:app, :minimum_price)} />.
              </div>
            </:help>
          </.input>
        </div>

        <:actions>
          <div class="mt-8 text-right">
            <.button
              phx-disable-with="Creating..."
              class="w-full px-5 py-3 text-base font-medium text-center text-white bg-primary-600 rounded-md hover:bg-primary-700 focus:ring-4 focus:ring-primary-300 sm:w-auto dark:bg-primary-600 dark:hover:bg-primary-600 dark:focus:ring-primary-800"
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
    # if price_type is free, set price to 0
    params =
      case product_params["price_type"] do
        "free" ->
          product_params
          |> Map.put("price", 0)
          |> Map.put("user", socket.assigns.current_user)

        _ ->
          Map.put(product_params, "user", socket.assigns.current_user)
      end

    socket =
      case Products.create_product(params) do
        {:ok, product} ->
          socket
          |> put_flash(:info, "Produk berhasil dibuat.")
          |> push_navigate(to: ~p"/products/#{product.id}/edit")

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

  defp show_price_input?(changeset) do
    Map.get(changeset.changes, :price_type, changeset.data.price_type) != :free
  end
end
