defmodule AppWeb.AdminLive.Withdrawal.Index do
  use AppWeb, :live_view
  require Logger
  alias App.Credits

  @result_limit 20
  @error_message "Maaf, terjadi kesalahan. Mohon segera hubungi tim support kami apabila hal ini terus terjadi."

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user |> App.Repo.preload(:bank_account)

    socket =
      socket
      |> assign(:show_modal, false)
      |> assign(:page_title, "Penarikan Dana")
      |> assign(:bank_account, user.bank_account)
      |> assign(:withdrawable_credits, Credits.withdrawable_credits_by_user(user))
      |> assign(:pending_credits, Credits.pending_credits_by_user(user))
      |> stream(:withdrawals, [])

    {:ok, socket}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  @impl true
  def handle_event("new_withdrawal", _params, socket) do
    user = socket.assigns.current_user
    bank_account = socket.assigns.bank_account

    withdrawal_fee = Application.get_env(:app, :withdrawal_fee)

    # don't allow user to create new withdrawal if they still have unprocessed (pending/submitted) withdrawal
    socket =
      case Credits.get_unprocessed_withdrawal_by_user(user) do
        nil ->
          now = Timex.now()
          amount = Credits.withdrawable_credits_by_user(user, now)

          params =
            %{
              amount: amount,
              service_fee: withdrawal_fee,
              amount_received: amount - withdrawal_fee,
              withdrawal_timestamp: now,
              recipient_bank_name: bank_account.bank_name,
              recipient_bank_acc_name: bank_account.account_name,
              recipient_bank_acc_number: bank_account.account_number
            }

          socket
          |> assign(:show_modal, true)
          |> assign(:withdrawal, nil)
          |> assign(:withdrawal_params, params)

        _ ->
          socket
          |> put_flash(
            :warning,
            "Anda memiliki penarikan dana dengan status PENDING atau SUBMITTED, mohon tunggu penarikan tersebut selesai sebelum membuat yang baru. Khusus penarikan dengan status PENDING, anda masih bisa membatalkannya sebelum membuat yang baru."
          )
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_withdrawal", params, socket) do
    params = Map.put(params, "user", socket.assigns.current_user)

    socket =
      case Credits.create_withdrawal(params) do
        {:ok, _withdrawal} ->
          socket
          |> put_flash(
            :info,
            "Silahkan cek email Anda dan klik link konfirmasi untuk melanjutkan proses penarikan dana."
          )
          |> assign(:show_modal, false)
          |> push_patch(to: ~p"/admin/withdrawals", replace: true)

        error ->
          Logger.error("Failed to create withdrawal: #{inspect(error)}")

          socket
          |> put_flash(
            :error,
            @error_message
          )
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_withdrawal", %{"id" => id}, socket) do
    withdrawal = Credits.get_withdrawal!(id)

    socket =
      case Credits.cancel_withdrawal(withdrawal) do
        {:ok, withdrawal} ->
          socket
          |> put_flash(:info, "Penarikan dana dibatalkan.")
          |> stream_insert(:withdrawals, withdrawal)

        error ->
          Logger.error("Failed to cancel withdrawal: #{inspect(error)}")

          socket
          |> put_flash(
            :error,
            @error_message
          )
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_withdrawal", %{"id" => id}, socket) do
    withdrawal = Credits.get_withdrawal!(id)

    params =
      %{
        amount: withdrawal.amount,
        service_fee: withdrawal.service_fee,
        amount_received: withdrawal.amount - withdrawal.service_fee,
        withdrawal_timestamp: withdrawal.withdrawal_timestamp,
        recipient_bank_name: withdrawal.recipient_bank_name,
        recipient_bank_acc_name: withdrawal.recipient_bank_acc_name,
        recipient_bank_acc_number: withdrawal.recipient_bank_acc_number
      }

    socket =
      socket
      |> assign(:show_modal, true)
      |> assign(:withdrawal, withdrawal)
      |> assign(:withdrawal_params, params)

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/withdrawals?page=#{page}", replace: true)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_params(socket, params)}
  end

  defp apply_params(socket, %{"token" => token}) do
    with {:ok, id} <- Credits.verify_withdrawal_confirmation_token(token),
         %{status: :pending} = withdrawal <- Credits.get_withdrawal(id),
         {:ok, _withdrawal} <- Credits.confirm_withdrawal(withdrawal) do
      socket
      |> put_flash(
        :info,
        "Penarikan dana telah dikonfirmasi, kami akan segera memproses penarikan dana Anda."
      )
      |> push_navigate(to: ~p"/admin/withdrawals")
    else
      {:error, _op, _value, _changeset} ->
        # error during updating withdrawal status

        socket
        |> put_flash(:error, @error_message)
        |> push_navigate(to: ~p"/admin/withdrawals")

      _ ->
        # other errors
        socket
        |> put_flash(:error, "Token konfirmasi tidak valid.")
        |> push_navigate(to: ~p"/admin/withdrawals")
    end
  end

  defp apply_params(socket, params) do
    page = Map.get(params, "page", "1") |> String.to_integer()

    {withdrawals, pagination} =
      fetch_withdrawals(socket.assigns.current_user, page)

    socket
    |> assign(:show_modal, false)
    |> assign(:pagination, pagination)
    |> stream(:withdrawals, withdrawals, reset: true)
  end

  defp fetch_withdrawals(user, page) do
    query = %{
      order_by: [:inserted_at],
      order_directions: [:desc],
      page_size: @result_limit,
      page: max(page, 1)
    }

    Credits.list_withdrawals_by_user(user, query)
  end
end
