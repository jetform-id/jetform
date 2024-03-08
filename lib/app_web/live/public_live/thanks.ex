defmodule AppWeb.PublicLive.Thanks do
  use AppWeb, :live_view
  alias App.Orders

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    order = Orders.get_order!(id)

    socket =
      case order.status in [:free, :paid] do
        true ->
          socket
          |> assign(:body_class, "bg-slate-50")
          |> assign(:page_title, "Terima kasih!")
          |> assign(:order, order)

        _ ->
          redirect(socket, to: ~p"/invoice/#{order.id}")
      end

    {:ok, socket}
  end
end
