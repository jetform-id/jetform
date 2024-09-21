defmodule AppWeb.Subdomain.Live.Checkout do
  use AppWeb, :live_view

  alias App.Products

  @impl true
  def mount(%{"slug" => slug} = params, _session, socket) do
    tenant = socket.assigns.tenant

    socket =
      case params["preview_token"] do
        nil ->
          # no preview token: check if product is live
          assign_product(socket, Products.get_live_product_by_user_and_slug!(tenant, slug))

        token ->
          # preview token: check if it's valid
          case Phoenix.Token.verify(socket, "preview_token", token) do
            {:ok, product_id} ->
              product = Products.get_product_by_user_and_slug!(tenant, slug)

              if product.id == product_id,
                do: assign_product(socket, product, true),
                else: raise(Ecto.NoResultsError, queryable: Products.Product)

            _ ->
              raise(Ecto.NoResultsError, queryable: Products.Product)
          end
      end

    {:ok, socket}
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
          socket
          |> redirect(external: "#{AppWeb.Utils.dashboard_url()}/invoices/#{order.id}/thanks")

        _ ->
          socket
          |> put_flash(:info, "Pesanan telah dibuat! silahkan lanjutkan dengan pembayaran.")
          |> redirect(external: "#{AppWeb.Utils.dashboard_url()}/invoices/#{order.id}")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{new_order: _order, new_payment: payment}, socket) do
    {:noreply, redirect(socket, external: payment.redirect_url)}
  end

  defp assign_product(socket, product, is_preview \\ false) do
    socket
    |> assign(:preview, is_preview)
    |> assign(:page_title, product.name)
    |> assign(:page_info, AppWeb.PageInfo.new(product))
    |> assign(:product, App.Repo.preload(product, :variants))
  end
end
