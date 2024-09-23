defmodule AppWeb.PublicLive.Embed do
  use AppWeb, :live_view
  alias App.Products

  @impl true
  def mount(%{"id" => id, "mode" => mode}, _session, socket) do
    product = Products.get_live_product!(id)

    {:ok,
     socket
     |> assign(:body_class, "")
     |> assign(:mode, mode)
     |> assign_product(product, false)}
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    product = Products.get_live_product!(id)
    {:ok, redirect(socket, external: AppWeb.Utils.product_url(product))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      :if={@product}
      module={AppWeb.AdminLive.Product.Components.Preview}
      id={@product.id}
      product={@product}
      preview={@preview}
    />
    """
  end

  # handle messages from Preview component

  @impl true
  def handle_info({:flash, :clear}, socket) do
    {:noreply, clear_flash(socket)}
  end

  @impl true
  def handle_info({:flash, type, message}, socket) do
    {:noreply, put_flash(socket, type, message)}
  end

  @impl true
  def handle_info(%{new_order: order, new_payment: nil}, socket) do
    socket =
      case order.status in [:free, :paid] do
        true ->
          push_event(socket, "openurl", %{
            "url" => "#{AppWeb.Utils.dashboard_url()}/invoices/#{order.id}/thanks"
          })

        _ ->
          socket
          |> put_flash(:info, "Pesanan telah dibuat! silahkan lanjutkan dengan pembayaran.")
          |> push_event("openurl", %{
            "url" => "#{AppWeb.Utils.dashboard_url()}/invoices/#{order.id}"
          })
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{new_order: _order, new_payment: payment}, socket) do
    {:noreply, push_event(socket, "openurl", %{"url" => payment.redirect_url})}
  end

  defp assign_product(socket, product, is_preview) do
    socket
    |> assign(:preview, is_preview)
    |> assign(:page_title, product.name)
    |> assign(:page_info, AppWeb.PageInfo.new(product))
    |> assign(:product, App.Repo.preload(product, :variants))
  end
end
