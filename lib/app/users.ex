defmodule App.Users do
  import Ecto.Query, warn: false

  alias App.Repo
  alias App.Users.{User, BankAccount}

  defdelegate tz_select_options(), to: User
  defdelegate tz_label(tz), to: User

  def set_role(user, role) do
    user
    |> User.changeset_role(%{role: role})
    |> Repo.update()
  end

  def get_bank_account_by_user(user) do
    case Repo.get_by(BankAccount, user_id: user.id) do
      nil -> nil
      bank_account -> bank_account |> Repo.preload(:user)
    end
  end

  def change_bank_account(bank_account, attrs) do
    bank_account |> BankAccount.changeset(attrs)
  end

  def create_bank_account(attrs) do
    %BankAccount{}
    |> BankAccount.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_bank_account(bank_account, attrs) do
    bank_account
    |> BankAccount.update_changeset(attrs)
    |> Repo.update()
  end
end
