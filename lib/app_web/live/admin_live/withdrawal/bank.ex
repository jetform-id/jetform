defmodule AppWeb.AdminLive.Withdrawal.Bank do
  use AppWeb, :live_view
  alias App.Users

  @impl true
  def mount(_params, _session, socket) do
    changeset =
      case Users.get_bank_account_by_user(socket.assigns.current_user) do
        {:ok, bank_account} -> changeset(bank_account)
        {:error, :not_found} -> changeset()
      end

    socket =
      socket
      |> assign(:page_title, "Bank Account")
      |> assign(:changeset, changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("save", %{"bank_account" => bank_account_params}, socket) do
    user = socket.assigns.current_user

    case Users.get_bank_account_by_user(user) do
      {:ok, bank_account} ->
        {:noreply, update_bank_account(socket, bank_account, bank_account_params)}

      {:error, :not_found} ->
        {:noreply, create_bank_account(socket, user, bank_account_params)}
    end
  end

  defp create_bank_account(socket, user, bank_account_params) do
    params = Map.put(bank_account_params, "user", user)

    case Users.create_bank_account(params) do
      {:ok, bank_account} ->
        socket
        |> assign(changeset: changeset(bank_account))
        |> put_flash(:info, "Your bank account detail has been saved.")

      {:error, changeset} ->
        assign(socket, changeset: changeset)
    end
  end

  defp update_bank_account(socket, bank_account, bank_account_params) do
    case Users.update_bank_account(bank_account, bank_account_params) do
      {:ok, bank_account} ->
        socket
        |> assign(changeset: changeset(bank_account))
        |> put_flash(:info, "Your bank account detail has been updated.")

      {:error, changeset} ->
        assign(socket, changeset: changeset)
    end
  end

  defp changeset() do
    Users.change_bank_account(%Users.BankAccount{}, %{})
  end

  defp changeset(bank_account) do
    Users.change_bank_account(bank_account, %{})
  end
end
