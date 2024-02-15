defmodule AppWeb.AdminLive.Product.Components.Preview do
  use AppWeb, :live_component
  use AppWeb, :html

  require Integer
  alias App.{Products, Orders}
  alias App.Orders.Order

  @impl true
  def render(assigns) do
    ~H"""
    <%!-- preview --%>
    <div class="p-6">
      <div class="mx-auto max-w-xl rounded-lg bg-white shadow-md">
        <img src={Products.cover_url(@product, :standard)} class="rounded-t-lg" />
        <hr />
        <div class="p-6">
          <h2 class="text-2xl font-semibold" id="preview" phx-update="replace">
            <%= @product.name %>
          </h2>
          <div class="mt-2 trix-content preview text-gray-600">
            <%= raw(@product.description) %>
          </div>

          <div :if={Products.has_details?(@product)} class="relative overflow-x-auto rounded-md mt-6">
            <table class="w-full text-sm text-left rtl:text-right text-gray-700 dark:text-gray-700">
              <tbody>
                <tr
                  :for={{item, index} <- Enum.with_index(@product.details["items"])}
                  class={if Integer.is_even(index), do: "bg-primary-100", else: "bg-primary-50"}
                >
                  <td
                    scope="row"
                    class="p-2 font-medium text-gray-700 whitespace-nowrap dark:text-gray-700"
                  >
                    <%= item["key"] %>
                  </td>
                  <td
                    scope="row"
                    class="p-2 font-medium text-gray-700 whitespace-nowrap dark:text-gray-700"
                  >
                    <.icon name="hero-chevron-right me-2 w-3 h-3" /> <%= item["value"] %>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div :if={@has_variants} class="mt-10 grid gap-2">
            <div :for={variant <- @product.variants} class="relative">
              <input
                class="peer hidden"
                id={"radio_" <> variant.id}
                type="radio"
                name="radio"
                phx-click={JS.push("select_variant", value: %{"id" => variant.id}, target: @myself)}
                checked={@selected_variant && variant.id == @selected_variant.id}
              />
              <span class="peer-checked:border-primary-700 absolute right-4 top-7 box-content block h-3 w-3 -translate-y-1/2 rounded-full border-8 border-gray-300 bg-white">
              </span>
              <label
                class="peer-checked:border-2 peer-checked:border-primary-700 peer-checked:bg-primary-50 flex cursor-pointer select-none rounded-lg border border-gray-300 p-4"
                for={"radio_" <> variant.id}
              >
                <div class="w-full">
                  <div class="font-semibold flex pr-12">
                    <span class="flex-1"><%= variant.name %></span>
                    Rp. <.price value={variant.price} />
                  </div>
                  <p class="text-slate-600 text-sm mt-1 pr-10">
                    <%= variant.description %>
                  </p>
                  <%!-- <div :if={variant.quantity} class="pt-2">
                        <span class="bg-yellow-100 text-yellow-800 text-xs font-medium inline-flex items-center px-2 py-0.5 rounded dark:bg-gray-700 dark:text-yellow-400 border border-yellow-400">
                          <.icon name="hero-clock w-3 h-3 me-1" /> Sisa <%= variant.quantity %>
                        </span>
                      </div> --%>
                </div>
              </label>
            </div>
          </div>

          <%!-- <div class="mt-6 border-t border-b py-2">
                <div class="flex items-center justify-between">
                  <p class="text-sm text-gray-400">Subtotal</p>
                  <p class="text-lg font-semibold text-gray-900">
                    <span class="text-xs font-normal text-gray-400">Rp.</span>
                    <.price value={Products.final_price(@product)} />
                  </p>
                </div>
                <div class="flex items-center justify-between">
                  <p class="text-sm text-gray-400">Fedex Delivery Enterprise</p>
                  <p class="text-lg font-semibold text-gray-900">Rp. 8.00</p>
                </div>
              </div> --%>
          <div
            :if={!@has_variants || (@has_variants && @selected_variant)}
            class="mt-6 flex items-center justify-between"
          >
            <p class="text-sm font-medium text-gray-900">Total</p>
            <p class="text-2xl font-semibold text-gray-900">
              <span class="text-xs font-normal text-gray-400">Rp.</span>
              <.price value={@total_price} />
            </p>
          </div>

          <.buy_button
            :if={@step == :cart}
            product={@product}
            is_free={@selected_variant && @total_price == 0}
            error={@error}
            on_click={JS.push("buy", target: @myself)}
          />

          <.checkout_form
            :if={@step == :checkout}
            is_free={@selected_variant && @total_price == 0}
            changeset={@checkout_changeset}
            submit_event={if @preview, do: "fake_order", else: "create_order"}
            submit_target={@myself}
            error={@error}
          />
        </div>
      </div>
      <p class="text-center p-3 text-sm text-gray-400">
        <.link navigate="/">powered by JetForm</.link>
      </p>
    </div>
    <%!-- end preview --%>
    """
  end

  attr :error, :string, default: nil
  attr :product, :map, required: true
  attr :is_free, :boolean, default: false
  attr :on_click, JS, default: %JS{}

  def buy_button(assigns) do
    ~H"""
    <div class="mt-6 text-center">
      <div
        :if={@error}
        class="p-4 mb-4 text-sm font-medium text-red-800 rounded-lg bg-red-50 dark:bg-gray-800 dark:text-red-400 border border-dashed border-red-800"
        role="alert"
      >
        <.icon name="hero-exclamation-triangle" /> <%= @error %>
      </div>

      <button
        phx-click={@on_click}
        type="button"
        class="group inline-flex w-full items-center justify-center rounded-md bg-primary-600 p-4 text-lg font-semibold text-white transition-all duration-200 ease-in-out focus:shadow hover:bg-primary-700"
      >
        <%= if @is_free do %>
          Dapatkan Akses Gratis!
        <% else %>
          <%= if Products.cta_custom?(@product.cta) do %>
            <%= @product.cta_text %>
          <% else %>
            <%= Products.cta_text(@product.cta) %>
          <% end %>
        <% end %>
      </button>
    </div>
    """
  end

  attr :is_free, :boolean, default: false
  attr :changeset, :map, required: true
  attr :submit_event, :string, required: true
  attr :submit_target, :any, required: true
  attr :error, :string, default: nil

  def checkout_form(assigns) do
    ~H"""
    <div class="mt-6 space-y-4">
      <hr class="my-4" />
      <%!-- <div>
        <p class="font-normal flex items-center">
          <.icon name="hero-identification me-1" />Data Pembeli
        </p>
      </div> --%>
      <.simple_form
        :let={f}
        for={@changeset}
        as={:order}
        phx-update="replace"
        phx-submit={@submit_event}
        phx-target={@submit_target}
      >
        <div class="space-y-6">
          <.input field={f[:customer_name]} type="text" label="Nama *" required />
          <div class="flex gap-4">
            <.input
              field={f[:customer_email]}
              type="email"
              label="Alamat email *"
              required
              wrapper_class="flex-1"
            />
            <.input
              field={f[:customer_phone]}
              type="text"
              label="No. HP / WhatsApp"
              wrapper_class="flex-1"
            />
          </div>

          <div class="border border-yellow-300 bg-yellow-100 rounded p-2 text-center">
            <p class="pl-6 mt-1 text-xs text-yellow-600">
              <.icon name="hero-exclamation-triangle" />
              Harap pastikan data di atas sudah benar. Pihak penjual dan JetForm tidak bertanggung jawab atas akibat dari kesalahan data yang dimasukan.
            </p>
          </div>

          <.input
            field={f[:confirm]}
            type="checkbox"
            label="Saya setuju dengan Syarat dan Ketentuan yang berlaku."
            wrapper_class="mx-auto"
            required
          />

          <div
            :if={@error}
            class="p-4 mb-4 text-sm font-medium text-red-800 rounded-lg bg-red-50 dark:bg-gray-800 dark:text-red-400 border border-dashed border-red-800"
            role="alert"
          >
            <.icon name="hero-exclamation-triangle" /> <%= @error %>
          </div>
        </div>

        <:actions>
          <button
            type="submit"
            class="mt-6 w-full items-center justify-center rounded-md bg-primary-600 p-4 text-lg font-semibold text-white transition-all duration-200 ease-in-out focus:shadow hover:bg-primary-700"
          >
            <%= if @is_free do
              "Kirim akses produk via email"
            else
              "Pembayaran"
            end %> <span aria-hidden="true">→</span>
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    variants = assigns.product.variants |> Enum.sort_by(& &1.inserted_at, :asc)

    socket =
      case Map.get(assigns, :changeset) do
        nil ->
          product = Map.put(assigns.product, :variants, variants)

          socket
          |> assign(assigns)
          |> assign(:product, product)
          |> assign(:preview, false)
          |> assign(:has_variants, Products.has_variants?(product))
          |> assign(:total_price, product.price)

        changeset ->
          product = Ecto.Changeset.apply_changes(changeset) |> Map.put(:variants, variants)

          socket
          |> assign(:preview, true)
          |> assign(:product, product)
          |> assign(:has_variants, Products.has_variants?(product))
          |> assign(:total_price, product.price)
      end
      |> assign(:selected_variant, nil)
      |> assign(:error, nil)
      |> assign(:step, :cart)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_variant", %{"id" => id}, socket) do
    variant = Enum.find(socket.assigns.product.variants, fn v -> v.id == id end)

    socket =
      socket
      |> assign(:selected_variant, variant)
      |> assign(:total_price, variant.price)
      |> assign(:error, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("buy", _params, socket) do
    with true <- socket.assigns.has_variants,
         nil <- socket.assigns.selected_variant do
      {:noreply, assign(socket, :error, "Silahkan pilih varian produk terlebih dahulu.")}
    else
      _ ->
        socket =
          socket
          |> assign(:step, :checkout)
          |> assign(:checkout_changeset, Orders.change_order(%Orders.Order{}))

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("fake_order", %{"order" => order_params}, socket) do
    order_params =
      order_params
      |> Map.put("product", socket.assigns.product)
      |> Map.put("product_variant", socket.assigns.selected_variant)
      |> Map.put("invoice_number", Orders.generate_invoice_number())
      |> Map.put("valid_until", Orders.valid_until_hours(1))

    changeset = Order.create_changeset(%Order{}, order_params)

    case Ecto.Changeset.apply_action(changeset, :insert) do
      {:ok, order} ->
        send(self(), {__MODULE__, order})
        {:noreply, assign(socket, :checkout_changeset, changeset)}

      {:error, changeset} ->
        {:noreply, assign(socket, :checkout_changeset, changeset)}
    end
  end

  @impl true
  def handle_event(
        "create_order",
        _params,
        %{assigns: %{product: %{is_live: false}}} = socket
      ) do
    {:noreply, assign(socket, :error, "Produk ini belum aktif.")}
  end

  @impl true
  def handle_event("create_order", %{"order" => order_params}, socket) do
    order_params =
      order_params
      |> Map.put("product", socket.assigns.product)
      |> Map.put("product_variant", socket.assigns.selected_variant)
      |> Map.put("invoice_number", Orders.generate_invoice_number())
      |> Map.put(
        "valid_until",
        Orders.valid_until_hours(Application.fetch_env!(:app, :order_validity_hours))
      )

    case Orders.create_order(order_params) do
      {:ok, order} ->
        send(self(), {__MODULE__, order})
        {:noreply, assign(socket, :checkout_changeset, Orders.change_order(order, %{}))}

      {:error, changeset} ->
        {:noreply, assign(socket, :checkout_changeset, changeset)}
    end
  end
end
