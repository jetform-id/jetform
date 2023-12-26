defmodule AppWeb.PublicLive.Checkout do
  use AppWeb, :live_view

  alias App.Products

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case socket.assigns.current_user do
      nil ->
        case Products.get_live_product_by_slug(slug) do
          nil -> not_found(socket)
          product -> found(socket, product)
        end

      user ->
        case Products.get_product_by_slug(slug) do
          nil ->
            not_found(socket)

          product ->
            if product.is_live || product.user_id == user.id,
              do: found(socket, product),
              else: not_found(socket)
        end
    end
  end

  defp found(socket, product) do
    socket =
      socket
      |> assign(:page_title, product.name)
      |> assign(:product, App.Repo.preload(product, :variants))

    {:ok, socket}
  end

  defp not_found(socket) do
    socket =
      socket
      |> assign(:page_title, "Halaman tidak ditemukan!")
      |> assign(:product, nil)

    {:ok, socket}
  end
end
