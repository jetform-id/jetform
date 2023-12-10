defmodule App.Users do
  alias App.Repo
  alias App.Users.BankAccount

  def get_bank_account_by_user(user) do
    case Repo.get_by(BankAccount, user_id: user.id) do
      nil -> {:error, :not_found}
      bank_account -> {:ok, bank_account}
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
    |> BankAccount.changeset(attrs)
    |> Repo.update()
  end
end
