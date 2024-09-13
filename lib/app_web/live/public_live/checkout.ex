defmodule AppWeb.PublicLive.Checkout do
  use AppWeb, :live_view

  alias App.Users
  alias App.Products

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug, "username" => username} = params, _uri, socket) do
    params = Map.drop(params, ["slug", "username"])

    seller = Users.get_by_username!(username)

    socket =
      case params["preview_token"] do
        nil ->
          # no preview token: check if product is live
          assign_product(
            socket,
            Products.get_live_product_by_user_and_slug!(seller, slug),
            params
          )

        token ->
          # preview token: check if it's valid
          case Phoenix.Token.verify(socket, "preview_token", token) do
            {:ok, product_id} ->
              product = Products.get_product_by_user_and_slug!(seller, slug)

              if product.id == product_id,
                do: assign_product(socket, product, params, true),
                else: raise(Ecto.NoResultsError, queryable: Products.Product)

            _ ->
              raise(Ecto.NoResultsError, queryable: Products.Product)
          end
      end

    {:noreply, socket}
  end

  @doc """
  If legacy product path is accessed, redirect to new path.
  """
  @impl true
  def handle_params(%{"slug" => slug} = params, _uri, socket) do
    params = Map.drop(params, ["slug"])
    product = Products.get_product_by_slug!(slug)

    {:noreply, redirect(socket, external: AppWeb.Utils.product_url(product, params: params))}
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
          socket |> redirect(to: ~p"/invoices/#{order.id}/thanks")

        _ ->
          socket
          |> put_flash(:info, "Pesanan telah dibuat! silahkan lanjutkan dengan pembayaran.")
          |> redirect(to: ~p"/invoices/#{order.id}")
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{new_order: _order, new_payment: payment}, socket) do
    {:noreply, redirect(socket, external: payment.redirect_url)}
  end

  defp assign_product(socket, product, params, is_preview \\ false) do
    if Application.get_env(:app, :enable_subdomains) do
      redirect(socket, external: AppWeb.Utils.product_url(product, params: params))
    else
      socket
      |> assign(:preview, is_preview)
      |> assign(:body_class, "bg-slate-300")
      |> assign(:page_title, product.name)
      |> assign(:page_info, AppWeb.PageInfo.new(product))
      |> assign(:product, App.Repo.preload(product, :variants))
    end
  end
end
