defmodule AppWeb.AdminLive.Withdrawal.Index do
  use AppWeb, :live_view
  alias App.Credits

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    socket =
      socket
      |> assign(:new_modal, false)
      |> assign(:withdrawable_credits, Credits.withdrawable_credits_by_user(user))
      |> stream(:withdrawals, Credits.list_withdrawals_by_user(user))

    {:ok, socket}
  end

  @impl true
  def handle_event("create_withdrawal", params, socket) do
    IO.inspect(socket.assigns.form)
    IO.inspect(params)
    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_params(socket, params)}
  end

  defp apply_params(socket, %{"action" => "new"}) do
    user = socket.assigns.current_user
    withdrawal_fee = Application.get_env(:app, :withdrawal_fee)

    # don't allow user to create new withdrawal if they still have unprocessed (pending/submitted) withdrawal
    case Credits.get_unprocessed_withdrawal_by_user(user) do
      nil ->
        now = Timex.now()
        amount = Credits.withdrawable_credits_by_user(user, now)

        params =
          %{
            amount: amount,
            service_fee: withdrawal_fee,
            amount_received: amount - withdrawal_fee,
            withdrawal_timestamp: now
          }

        socket
        |> assign(:new_modal, true)
        |> assign(:withdrawal_params, params)
        |> assign(:page_title, "Buat Penarikan Baru")

      _ ->
        socket
        |> put_flash(
          :warning,
          "Anda masih memiliki penarikan yang belum selesai, mohon tunggu penarikan itu selesai sebelum membuat yang baru. Khusus buat penarikan dengan status PENDING, anda dapat membatalkannya terlebih dahulu sebelum membuat yang baru."
        )
    end
  end

  defp apply_params(socket, _params) do
    socket
    |> assign(:new_modal, false)
    |> assign(:page_title, "Penarikan Dana")
  end
end
