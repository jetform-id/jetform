defmodule AppWeb.ProductLive.Components.Preview do
  use AppWeb, :html
  require Integer
  alias App.Products

  attr :product, :map, required: true
  attr :changeset, :map, required: false

  def render(assigns) do
    assigns =
      case Map.get(assigns, :changeset) do
        nil ->
          assigns

        changeset ->
          assign(assigns, :product, Ecto.Changeset.apply_changes(changeset))
      end

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

              <form class="mt-10 grid gap-2">
                <div class="relative">
                  <input class="peer hidden" id="radio_0" type="radio" name="radio" checked />
                  <span class="peer-checked:border-primary-700 absolute right-4 top-8 box-content block h-3 w-3 -translate-y-1/2 rounded-full border-8 border-gray-300 bg-white">
                  </span>
                  <label
                    class="peer-checked:border-2 peer-checked:border-primary-700 peer-checked:bg-primary-50 flex cursor-pointer select-none rounded-lg border border-gray-300 p-4"
                    for="radio_0"
                  >
                    <div>
                      <span class="mt-2 font-semibold">Basic</span>
                      <p class="text-slate-600 text-sm text-sm mt-1 pr-10">Delivery: 2-4 Days</p>
                    </div>
                  </label>
                </div>

                <div class="relative">
                  <input class="peer hidden" id="radio_1" type="radio" name="radio" />
                  <span class="peer-checked:border-primary-700 absolute right-4 top-8 box-content block h-3 w-3 -translate-y-1/2 rounded-full border-8 border-gray-300 bg-white">
                  </span>
                  <label
                    class="peer-checked:border-2 peer-checked:border-primary-700 peer-checked:bg-primary-50 flex cursor-pointer select-none rounded-lg border border-gray-300 p-4"
                    for="radio_1"
                  >
                    <div>
                      <span class="mt-2 font-semibold">Fedex Delivery Pro (+$15)</span>
                      <p class="text-slate-600 text-sm mt-1 pr-10">
                        Thank you for the workshop, it was very productive meeting. I can't wait to start working on this new project with you guys. But first things first, I'am waiting for the offer and pitch deck from you. It would be great to get it by the end o the month.
                      </p>
                    </div>
                  </label>
                </div>
                <div class="relative">
                  <input class="peer hidden" id="radio_2" type="radio" name="radio" />
                  <span class="peer-checked:border-primary-700 absolute right-4 top-8 box-content block h-3 w-3 -translate-y-1/2 rounded-full border-8 border-gray-300 bg-white">
                  </span>
                  <label
                    class="peer-checked:border-2 peer-checked:border-primary-700 peer-checked:bg-primary-50 flex cursor-pointer select-none rounded-lg border border-gray-300 p-4"
                    for="radio_2"
                  >
                    <div>
                      <span class="mt-2 font-semibold">Fedex Delivery Enterprise (+25)</span>
                      <p class="text-slate-600 text-sm text-sm mt-1 pr-10">Delivery: 2-4 Days</p>
                    </div>
                  </label>
                </div>
              </form>

              <div class="mt-6 border-t border-b py-2">
                <div class="flex items-center justify-between">
                  <p class="text-sm text-gray-400">Subtotal</p>
                  <p class="text-lg font-semibold text-gray-900">
                    <span class="text-xs font-normal text-gray-400">Rp.</span>
                    <.price value={Products.final_price(@product)} />
                  </p>
                </div>
                <%!-- <div class="flex items-center justify-between">
                  <p class="text-sm text-gray-400">Fedex Delivery Enterprise</p>
                  <p class="text-lg font-semibold text-gray-900">Rp. 8.00</p>
                </div> --%>
              </div>
              <div class="mt-6 flex items-center justify-between">
                <p class="text-sm font-medium text-gray-900">Total</p>
                <p class="text-2xl font-semibold text-gray-900">
                  <span class="text-xs font-normal text-gray-400">Rp.</span>
                  <.price value={Products.final_price(@product)} />
                </p>
              </div>

              <div class="mt-6 text-center">
                <button
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
end
