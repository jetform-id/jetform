defmodule AppWeb.PayoutController do
  use AppWeb, :controller
  alias App.Users

  def edit_bank_account(conn, _params) do
    case Users.get_bank_account_by_user(conn.assigns.current_user) do
      {:ok, bank_account} ->
        changeset = Users.change_bank_account(bank_account, %{})
        render(conn, :edit_bank_account, changeset: changeset, action: ~p"/payouts/bank-account")

      {:error, :not_found} ->
        changeset = Users.change_bank_account(%Users.BankAccount{}, %{})
        render(conn, :edit_bank_account, changeset: changeset, action: ~p"/payouts/bank-account")
    end
  end

  def create_or_update_bank_account(conn, %{"bank_account" => bank_account_params}) do
    user = conn.assigns.current_user

    case Users.get_bank_account_by_user(user) do
      {:ok, bank_account} ->
        update_bank_account(conn, bank_account, bank_account_params)

      {:error, :not_found} ->
        create_bank_account(conn, user, bank_account_params)
    end
  end

  defp create_bank_account(conn, user, bank_account_params) do
    params = Map.put(bank_account_params, "user", user)

    case Users.create_bank_account(params) do
      {:ok, _bank_account} ->
        conn
        |> put_flash(:info, "Your bank account detail has been saved.")
        |> redirect(to: ~p"/payouts/bank-account")

      {:error, changeset} ->
        render(conn, :edit_bank_account, changeset: changeset, action: ~p"/payouts/bank-account")
    end
  end

  defp update_bank_account(conn, bank_account, bank_account_params) do
    case Users.update_bank_account(bank_account, bank_account_params) do
      {:ok, _bank_account} ->
        conn
        |> put_flash(:info, "Your bank account detail has been updated.")
        |> redirect(to: ~p"/payouts/bank-account")

      {:error, changeset} ->
        render(conn, :edit_bank_account, changeset: changeset, action: ~p"/payouts/bank-account")
    end
  end
end
