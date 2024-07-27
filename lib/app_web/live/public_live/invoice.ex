defmodule AppWeb.PublicLive.Invoice do
  use AppWeb, :live_view
  alias App.Orders
  alias AppWeb.AdminLive.Product.Components.Commons

  @tick_every 1_000

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    order = Orders.get_order!(id) |> App.Repo.preload(:user)

    # subscribe for order changes
    Phoenix.PubSub.subscribe(App.PubSub, "order:#{order.id}")

    brand_info =
      case App.Users.brand_info_complete?(order.user) do
        true -> App.Users.get_brand_info(order.user)
        false -> nil
      end

    socket =
      socket
      |> assign(:body_class, "bg-slate-300")
      |> assign(:page_title, "Invoice #" <> order.invoice_number)
      |> assign(:order, order)
      |> assign(:brand_info, brand_info)
      |> assign(:status, order.status)

    socket = if order.status == :pending, do: tick(socket, order), else: socket

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"payment_id" => payment_id}, _uri, socket) do
    case Orders.get_payment(payment_id) do
      %{trx_status: "pending"} = payment ->
        Orders.refresh_payment(payment)
        {:noreply, socket}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_params(_, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_payment", _params, socket) do
    # check if there's already an empty payment for this order
    # if there is, redirect to its `redirect_url`, otherwise create a new one
    case Orders.get_empty_payment(socket.assigns.order) do
      nil ->
        case Orders.create_payment(socket.assigns.order) do
          {:ok, payment} ->
            {:noreply, redirect(socket, external: payment.redirect_url)}

          {:error, :expire_soon, _} ->
            {:noreply,
             put_flash(
               socket,
               :warning,
               "Maaf, order ini hampir kadaluarsa! Silahkan membuat order baru demi kelancaran proses pembayaran."
             )}

          {:error, _, _} ->
            {:noreply, put_flash(socket, :error, "Maaf! Terjadi kesalahan.")}
        end

      payment ->
        {:noreply, redirect(socket, external: payment.redirect_url)}
    end
  end

  @doc """
  Handle order changes event received from PubSub.
  """
  @impl true
  def handle_info("order:updated", socket) do
    order = App.Repo.reload!(socket.assigns.order)
    socket = assign(socket, :order, order)

    case order.status do
      :free ->
        {:noreply, redirect(socket, to: ~p"/invoice/#{order.id}/thanks")}

      :paid ->
        {:noreply, redirect(socket, to: ~p"/invoice/#{order.id}/thanks")}

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
