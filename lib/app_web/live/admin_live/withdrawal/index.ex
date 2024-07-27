defmodule AppWeb.AdminLive.Withdrawal.Index do
  use AppWeb, :live_view
  require Logger
  alias App.Credits
  alias AppWeb.AdminLive.Withdrawal.Components.Commons

  @result_limit 20
  @error_message "Maaf, terjadi kesalahan. Mohon segera hubungi tim support kami apabila hal ini terus terjadi."

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user |> App.Repo.preload(:bank_account)

    socket =
      socket
      |> assign(:show_modal, false)
      |> assign(:page_title, "Penarikan Dana")
      |> allow_upload(:admin_transfer_prove,
        accept: ~w(.jpg .jpeg .png),
        max_file_size: 1_000_000
      )
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
          |> assign(:admin_form, nil)

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
          |> push_navigate(to: ~p"/withdrawals", replace: true)

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
      case Credits.update_withdrawal(withdrawal, %{"status" => "cancelled"}) do
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
      |> assign(
        :admin_form,
        to_form(Credits.change_withdrawal(withdrawal))
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "admin:update_withdrawal",
        %{"withdrawal" => withdrawal_params},
        %{assigns: %{current_user: %{role: :admin}}} = socket
      ) do
    params = maybe_put_attachment(socket, withdrawal_params, :admin_transfer_prove)

    socket =
      case Credits.update_withdrawal(socket.assigns.withdrawal, params) do
        {:ok, withdrawal} ->
          socket
          |> put_flash(:info, "Penarikan dana berhasil diupdate.")
          |> stream_insert(:withdrawals, withdrawal)
          |> assign(:show_modal, false)

        error ->
          Logger.error("Failed to update withdrawal: #{inspect(error)}")

          socket
          |> put_flash(
            :error,
            @error_message
          )
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "admin:update_withdrawal_validate",
        %{"withdrawal" => withdrawal_params},
        %{assigns: %{current_user: %{role: :admin}}} = socket
      ) do
    socket =
      socket
      |> assign(
        :admin_form,
        to_form(Credits.change_withdrawal(socket.assigns.withdrawal, withdrawal_params))
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    {:noreply, push_patch(socket, to: ~p"/withdrawals?page=#{page}", replace: true)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_params(socket, params)}
  end

  defp apply_params(socket, %{"token" => token}) do
    with {:ok, id} <- Credits.verify_withdrawal_confirmation_token(token),
         %{status: :pending} = withdrawal <- Credits.get_withdrawal(id),
         {:ok, _withdrawal} <- Credits.update_withdrawal(withdrawal, %{"status" => "submitted"}) do
      socket
      |> put_flash(
        :info,
        "Penarikan dana telah dikonfirmasi, kami akan segera memproses penarikan dana Anda."
      )
      |> push_navigate(to: ~p"/withdrawals")
    else
      {:error, _op, _value, _changeset} ->
        # error during updating withdrawal status

        socket
        |> put_flash(:error, @error_message)
        |> push_navigate(to: ~p"/withdrawals")

      _ ->
        # other errors
        socket
        |> put_flash(:error, "Token konfirmasi tidak valid.")
        |> push_navigate(to: ~p"/withdrawals")
    end
  end

  defp apply_params(socket, params) do
    query = %{
      order_by: [:inserted_at],
      order_directions: [:desc],
      page_size: @result_limit,
      page: max(1, Map.get(params, "page", "1") |> String.to_integer())
    }

    {withdrawals, pagination} =
      Credits.list_withdrawals_by_user!(socket.assigns.current_user, query)

    socket
    |> assign(:show_modal, false)
    |> assign(:pagination, pagination)
    |> stream(:withdrawals, withdrawals, reset: true)
  end

  defp maybe_put_attachment(socket, params, field) when is_atom(field) do
    case uploaded_entries(socket, field) do
      {[_ | _], []} ->
        [file_path] = uploaded_image_paths(socket, field)
        Map.put(params, Atom.to_string(field), file_path)

      _ ->
        params
    end
  end

  defp uploaded_image_paths(socket, field) when is_atom(field) do
    consume_uploaded_entries(socket, field, fn %{path: path}, entry ->
      updated_path = Path.join(Path.dirname(path), entry.client_name)
      File.cp!(path, updated_path)
      {:ok, updated_path}
    end)
  end
end
