defmodule AppWeb.PublicLive.Invoice do
  use AppWeb, :live_view
  alias App.Orders
  alias AppWeb.ProductLive.Components.Commons

  @tick_every 5_000

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    order = Orders.get_order!(id)

    # subscribe for order changes
    Phoenix.PubSub.subscribe(App.PubSub, "order:#{order.id}")

    socket =
      socket
      |> assign(:page_title, "Invoice #" <> order.invoice_number)
      |> assign(:order, order)
      |> assign(:status, order.status)

    socket = if order.status == :pending, do: tick(socket, order), else: socket

    {:ok, socket}
  end

  @doc """
  Handle order changes event received from PubSub.
  """
  @impl true
  def handle_info("order:updated", socket) do
    order = App.Repo.reload!(socket.assigns.order)
    socket = assign(socket, :order, order)

    case order.status do
      :paid ->
        {:noreply, put_flash(socket, :info, "Order telah lunas!")}

      :expired ->
        {:noreply, put_flash(socket, :error, "Order telah kadaluarsa!")}

      :cancelled ->
        {:noreply, put_flash(socket, :error, "Order telah dibatalkan!")}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info("tick", socket) do
    case socket.assigns.order.status do
      :pending ->
        {:noreply, tick(socket, socket.assigns.order)}

      _ ->
        {:noreply, socket}
    end
  end

  defp tick(socket, order) do
    Process.send_after(self(), "tick", @tick_every)
    assign(socket, :expire_in_secs, Orders.time_before_expired(order))
  end
end
