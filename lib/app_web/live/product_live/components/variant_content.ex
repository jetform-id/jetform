defmodule AppWeb.ProductLive.Components.VariantContent do
  use AppWeb, :live_component
  use AppWeb, :html

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"variant-content-for-product-" <> @id} class="p-4 md:p-8 dark:bg-gray-800 space-y-4">
    </div>
    """
  end
end
