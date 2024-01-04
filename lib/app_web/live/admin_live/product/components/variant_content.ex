defmodule AppWeb.AdminLive.Product.Components.VariantContent do
  use AppWeb, :live_component
  use AppWeb, :html

  alias App.Products
  alias AppWeb.AdminLive.Product.Components.VariantContentItem

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"variant-content-for-product-" <> @id} class="p-4 md:p-8 dark:bg-gray-800 space-y-4">
      <%!-- variant list --%>
      <div id="variant-list-for-content" class="space-y-4" phx-update="stream">
        <.live_component
          :for={{dom_id, variant} <- @streams.variants}
          module={VariantContentItem}
          id={dom_id}
          product={@product}
          variant={variant}
        />
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> stream(:variants, Products.list_variants_by_product(assigns.product))

    {:ok, socket}
  end
end
