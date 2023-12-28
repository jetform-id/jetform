defmodule AppWeb.PublicLive.Invoice do
  use AppWeb, :live_view
  alias App.Orders
  alias AppWeb.ProductLive.Components.Commons

  @refresh_every 5_000

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    order = Orders.get_order!(id)

    socket =
      socket
      |> assign(:page_title, "Invoice #" <> order.invoice_number)
      |> assign(:order, order)
      |> assign(:status, Orders.status(order))

    socket = if Orders.status(order) == :pending, do: refresh(socket, order), else: socket

    {:ok, socket}
  end

  @impl true
  def handle_info("refresh", socket) do
    order = App.Repo.reload!(socket.assigns.order)

    case Orders.status(order) do
      :pending ->
        {:noreply, refresh(socket, order)}

      status ->
        case status do
          :paid ->
            {:noreply,
             socket |> assign(:status, status) |> put_flash(:info, "Order telah lunas!")}

          :expired ->
            {:noreply,
             socket |> assign(:status, status) |> put_flash(:error, "Order telah kadaluarsa!")}

          :cancelled ->
            {:noreply,
             socket |> assign(:status, status) |> put_flash(:error, "Order telah dibatalkan!")}
        end
    end
  end

  defp refresh(socket, order) do
    Process.send_after(self(), "refresh", @refresh_every)
    assign(socket, :expire_in_secs, Orders.time_before_expired(order))
  end
end
