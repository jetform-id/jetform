defmodule AppWeb.ProductLive.Components.Preview do
  use AppWeb, :live_component
  require Integer
  alias App.Products

  @impl true
  def render(assigns) do
    ~H"""
    <div class="border rounded-lg shadow bg-gray-300 dark:bg-gray-800 dark:border-gray-700">
      <ul
        class="flex flex-wrap text-sm font-medium text-center text-gray-500 border-b border-gray-200 rounded-t-lg bg-gray-50 dark:border-gray-700 dark:text-gray-400 dark:bg-gray-800"
        role="tablist"
      >
        <li class="me-2">
          <button
            type="button"
            role="tab"
            aria-selected="true"
            class="inline-block p-4 rounded-ss-lg dark:bg-gray-800 dark:text-primary-500"
          >
            <.icon name="hero-eye" /> Preview
          </button>
        </li>
      </ul>
      <div>
        <%!-- preview --%>
        <div class="p-6">
          <div class="mx-auto max-w-xl rounded-lg border bg-white shadow-md">
            <img src={Products.cover_url(@product, :standard)} class="rounded-t-lg" />

            <div class="p-6">
              <h2 class="text-2xl font-semibold" id="preview" phx-update="replace">
                <%= @product.name %>
              </h2>
              <p class="mt-2 text-sm text-gray-600">
                <%= @product.description %>
              </p>

              <div
                :if={Products.has_details?(@product)}
                class="relative overflow-x-auto rounded-md mt-6"
              >
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
                        : <%= item["value"] %>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div :if={@has_versions} class="mt-10 grid gap-2">
                <div :for={version <- @product.versions} class="relative">
                  <input
                    class="peer hidden"
                    id={"radio_" <> version.id}
                    type="radio"
                    name="radio"
                    phx-click={
                      JS.push("select_version", value: %{"id" => version.id}, target: @myself)
                    }
                    checked={@selected_version && version.id == @selected_version.id}
                  />
                  <span class="peer-checked:border-primary-700 absolute right-4 top-8 box-content block h-3 w-3 -translate-y-1/2 rounded-full border-8 border-gray-300 bg-white">
                  </span>
                  <label
                    class="peer-checked:border-2 peer-checked:border-primary-700 peer-checked:bg-primary-50 flex cursor-pointer select-none rounded-lg border border-gray-300 p-4"
                    for={"radio_" <> version.id}
                  >
                    <div>
                      <span class="mt-2 font-semibold">
                        <%= version.name %> (Rp. <.price value={version.price} />)
                      </span>
                      <p class="text-slate-600 text-sm text-sm mt-1 pr-10">
                        <%= version.description %>
                      </p>
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
                :if={!@has_versions || (@has_versions && @selected_version)}
                class="mt-6 flex items-center justify-between"
              >
                <p class="text-sm font-medium text-gray-900">Total</p>
                <p class="text-2xl font-semibold text-gray-900">
                  <span class="text-xs font-normal text-gray-400">Rp.</span>
                  <.price value={@total_price} />
                </p>
              </div>

              <div class="mt-6 text-center">
                <div
                  :if={@error}
                  class="p-4 mb-4 text-sm text-red-800 rounded-lg bg-red-50 dark:bg-gray-800 dark:text-red-400"
                  role="alert"
                >
                  <%= @error %>
                </div>

                <button
                  phx-click={JS.push("buy", target: @myself)}
                  type="button"
                  class="group inline-flex w-full items-center justify-center rounded-md bg-primary-600 p-4 text-lg font-semibold text-white transition-all duration-200 ease-in-out focus:shadow hover:bg-gray-800"
                >
                  <%= if Products.cta_custom?(@product.cta) do %>
                    <%= @product.cta_text %>
                  <% else %>
                    <%= Products.cta_text(@product.cta) %>
                  <% end %>
                </button>
              </div>
            </div>
          </div>
        </div>

        <%!-- end preview --%>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      case Map.get(assigns, :changeset) do
        nil ->
          socket

        changeset ->
          versions = assigns.product.versions |> Enum.sort_by(& &1.inserted_at, :asc)
          product = Ecto.Changeset.apply_changes(changeset) |> Map.put(:versions, versions)

          socket
          |> assign(:product, product)
          |> assign(:has_versions, !Enum.empty?(versions))
          |> assign(:selected_version, nil)
          |> assign(:error, nil)
          |> assign(:total_price, product.price)
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("select_version", %{"id" => id}, socket) do
    version = Enum.find(socket.assigns.product.versions, fn v -> v.id == id end)

    socket =
      socket
      |> assign(:selected_version, version)
      |> assign(:total_price, version.price)
      |> assign(:error, nil)

    {:noreply, socket}
  end

  @impl true
  def handle_event("buy", _params, socket) do
    if socket.assigns.has_versions do
      case socket.assigns.selected_version do
        nil ->
          {:noreply, assign(socket, :error, "Please select a version!")}

        version ->
          send(self(), {__MODULE__, :buy_version, version})
          {:noreply, socket}
      end
    else
      send(self(), {__MODULE__, :buy, socket.assigns.product})
      {:noreply, socket}
    end
  end
end
