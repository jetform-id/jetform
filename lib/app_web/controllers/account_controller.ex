defmodule AppWeb.AccountController do
  use AppWeb, :controller

  alias App.Users
  alias App.Plans

  def edit(conn, _params) do
    plan = Plans.get(conn.assigns.current_user.plan)
    user = conn.assigns.current_user |> App.Repo.preload(:bank_account)

    render(conn, :edit,
      page_title: "Edit Akun",
      user: user,
      user_changeset: Pow.Plug.change_user(conn),
      bank_acc_changeset: bank_acc_changeset(user.bank_account),
      plan: plan
    )
  end

  @doc """
  Because we manually handle user update, we also need to make sure that the email confirmation is handled properly.
  """
  def update(conn, %{"user" => user_params}) do
    case Pow.Plug.update_user(conn, user_params) do
      {:ok, user, conn} ->
        case PowEmailConfirmation.Phoenix.ControllerCallbacks.before_respond(
               Pow.Phoenix.RegistrationController,
               :update,
               {:ok, user, conn},
               %{}
             ) do
          {:ok, _user, conn} ->
            conn
            |> put_flash(:info, "Perubahan detail akun berhasil disimpan.")
            |> redirect(to: ~p"/account")

          {:halt, conn} ->
            halt(conn)
        end

      {:error, changeset, conn} ->
        user = conn.assigns.current_user |> App.Repo.preload(:bank_account)

        render(conn, :edit,
          page_title: "Edit Akun",
          user: user,
          user_changeset: changeset,
          bank_acc_changeset: bank_acc_changeset(user.bank_account),
          plan: Plans.get(user.plan)
        )
    end
  end

  def update(conn, %{"bank_account" => bank_account_params}) do
    user = conn.assigns.current_user

    case Users.get_bank_account_by_user(user) do
      nil -> create_bank_account(conn, user, bank_account_params)
      bank_account -> update_bank_account(conn, user, bank_account, bank_account_params)
    end
  end

  defp create_bank_account(conn, user, bank_account_params) do
    params = Map.put(bank_account_params, "user", user)

    case Users.create_bank_account(params) do
      {:ok, _bank_account} ->
        conn
        |> put_flash(:info, "Data akun bank anda telah disimpan.")
        |> redirect(to: ~p"/account")

      {:error, changeset} ->
        render(conn, :edit,
          plan: Plans.get(user.plan),
          user_changeset: Pow.Plug.change_user(conn),
          bank_acc_changeset: changeset
        )
    end
  end

  defp update_bank_account(conn, user, bank_account, bank_account_params) do
    case Users.update_bank_account(bank_account, bank_account_params) do
      {:ok, _bank_account} ->
        conn
        |> put_flash(:info, "Data akun bank anda telah diperbarui.")
        |> redirect(to: ~p"/account")

      {:error, changeset} ->
        render(conn, :edit,
          plan: Plans.get(user.plan),
          user_changeset: Pow.Plug.change_user(conn),
          bank_acc_changeset: changeset
        )
    end
  end

  defp bank_acc_changeset(nil) do
    Users.change_bank_account(%Users.BankAccount{}, %{})
  end

  defp bank_acc_changeset(bank_account) do
    Users.change_bank_account(bank_account, %{})
  end
end
