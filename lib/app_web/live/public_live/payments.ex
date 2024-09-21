defmodule AppWeb.PublicLive.Payments do
  use AppWeb, :live_view
  alias App.Orders

  @tick_every 10_000

  @impl true
  def mount(%{"id" => id, "token" => token}, _session, socket) do
    payment = Orders.get_payment!(id) |> App.Repo.preload(:order)
    order = payment.order

    socket =
      case get_session(token) do
        {:ok, data, _} ->
          # subscribe for order changes
          Phoenix.PubSub.subscribe(App.PubSub, "payment:#{payment.id}")

          socket
          |> assign(:token, token)
          |> assign(:payment, payment)
          |> assign(:payment_session, data)
          |> assign(
            :payment_channel,
            Orders.find_payment_channel(data.method <> ":" <> data.channel)
          )
          |> tick()

        {:error, reason, _} ->
          assign(socket, :status, reason)
      end

    {:ok,
     socket
     |> assign(:allow_switch_or_cancel, false)
     |> assign(:show_cancel_payment_modal, false)
     |> assign(:show_switch_payment_modal, false)
     |> assign(:page_title, "Payment for #" <> order.invoice_number)}
  end

  @impl true
  def handle_params(_, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> clear_flash()
     |> assign(:show_cancel_payment_modal, false)
     |> assign(:show_switch_payment_modal, false)}
  end

  # Handle Switch Payment
  @impl true
  def handle_event("switch_payment_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_cancel_payment_modal, false)
      |> assign(:show_switch_payment_modal, true)
      |> assign_async(:payment_channels, fn ->
        {:ok, %{payment_channels: Orders.list_payment_channels()}}
      end)

    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_payment", %{"payment_channel" => channel}, socket) do
    socket =
      if channel == socket.assigns.payment_channel.key do
        # if the selected channel is the same as the current channel, do nothing
        socket
        |> clear_flash()
        |> assign(:show_switch_payment_modal, false)
      else
        case Orders.switch_payment(socket.assigns.payment, channel) do
          {:ok, payment} ->
            socket
            |> put_flash(:info, "Pembayaran telah diubah.")
            |> redirect(external: payment.redirect_url)

          {:error, :provider_error} ->
            put_flash(
              socket,
              :error,
              "Maaf, metode pembayaran yang Anda pilih sedang mengalami gangguan."
            )

          {:error, _} ->
            put_flash(socket, :error, "Maaf, gagal mengubah metode pembayaran.")
        end
      end

    {:noreply, socket}
  end

  # Handle Cancel Payment
  @impl true
  def handle_event("cancel_payment_modal", _params, socket) do
    socket =
      socket
      |> assign(:show_switch_payment_modal, false)
      |> assign(:show_cancel_payment_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_payment", params, socket) do
    payment = socket.assigns.payment

    reason =
      case params do
        %{"reason" => "others", "reason-text" => reason} ->
          String.trim(reason)
          |> case do
            "" -> nil
            reason -> reason
          end

        %{"reason-text" => ""} ->
          nil

        %{"reason" => reason} ->
          reason
      end

    case Orders.cancel_payment(payment, cancel_order: true, reason: reason) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Pembayaran telah dibatalkan.")
         |> redirect(to: ~p"/invoices/#{payment.order_id}")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Maaf, gagal membatalkan pembayaran.")}
    end
  end

  @doc """
  Handle order changes event received from PubSub.
  """
  @impl true
  def handle_info("payment:updated", socket) do
    payment = App.Repo.reload!(socket.assigns.payment)
    socket = assign(socket, :payment, payment)

    case payment.trx_status do
      "paid" ->
        {:noreply, redirect(socket, to: ~p"/invoices/#{payment.order_id}/thanks")}

      "expire" ->
        {:noreply, assign(socket, :payment, payment)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info("tick", socket) do
    {:noreply, tick(socket)}
  end

  defp tick(socket) do
    session = get_session(socket.assigns.token)
    status = payment_status(socket.assigns.payment, session)

    case status do
      :ok ->
        {:ok, _data, expire_at} = session

        Process.send_after(self(), "tick", @tick_every)
        expire_in_secs = Timex.diff(expire_at, Timex.now(), :second)

        socket
        |> assign(:status, status)
        |> assign(:allow_switch_or_cancel, expire_in_secs > 60 * 5)
        |> assign(:expire_in_secs, expire_in_secs)

      _ ->
        assign(socket, :status, status)
    end
  end

  defp get_session(token) do
    case Phoenix.Token.verify(AppWeb.Endpoint, "payment", token) do
      {:ok, data} -> {:ok, data, data.token_expired_at}
      {:error, reason} -> {:error, reason, nil}
    end
  end

  defp payment_status(payment, session) do
    # status determined by session/token expiry or payment status
    session_status =
      case session do
        {:ok, _, _} -> :ok
        {:error, reason, _} -> reason
      end

    cond do
      session_status != :ok -> session_status
      payment.trx_status == "expire" -> :expired
      true -> :ok
    end
  end
end
