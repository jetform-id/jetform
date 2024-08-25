defmodule AppWeb.PublicLive.Checkout do
  use AppWeb, :live_view

  alias App.Users
  alias App.Products

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug, "username" => username}, _uri, socket) do
    seller = Users.get_by_username!(username)

    case socket.assigns.current_user do
      nil ->
        # non logged in user: only live products are accessible
        return_product(socket, Products.get_live_product_by_user_and_slug!(seller, slug))

      user ->
        # logged in user: product is accessible if it's live or user is the owner
        product = Products.get_product_by_user_and_slug!(seller, slug)

        if product.is_live || product.user_id == user.id,
          do: return_product(socket, product),
          else: raise(Ecto.NoResultsError, queryable: Products.Product)
    end
  end

  @doc """
  If legacy product path is accessed, redirect to new path.
  """
  @impl true
  def handle_params(%{"slug" => slug} = params, _uri, socket) do
    params = Map.drop(params, ["slug"])

    product = Products.get_product_by_slug!(slug) |> App.Repo.preload(:user)
    user = product.user
    {:noreply, redirect(socket, to: ~p"/#{user.username}/#{slug}?#{params}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.live_component
      :if={@product}
      module={AppWeb.AdminLive.Product.Components.Preview}
      id={@product.id}
      product={@product}
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
  def handle_info({:new_order, order}, socket) do
    socket =
      case order.status in [:free, :paid] do
        true ->
          socket |> redirect(to: ~p"/invoice/#{order.id}/thanks")

        _ ->
          socket
          |> put_flash(:info, "Pesanan telah dibuat! silahkan lanjutkan dengan pembayaran.")
          |> redirect(to: ~p"/invoice/#{order.id}")
      end

    {:noreply, socket}
  end

  defp return_product(socket, product) do
    socket =
      socket
      |> assign(:enable_tracking, product.is_live)
      |> assign(:body_class, "bg-slate-300")
      |> assign(:page_title, product.name)
      |> assign(:page_info, AppWeb.PageInfo.new(product))
      |> assign(:product, App.Repo.preload(product, :variants))

    {:noreply, socket}
  end
end
