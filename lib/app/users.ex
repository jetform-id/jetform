defmodule App.Users do
  import Ecto.Query, warn: false

  alias App.Repo
  alias App.Users.{User, BankAccount, APIKey, BankList}

  defdelegate tz_select_options(), to: User
  defdelegate tz_label(tz), to: User

  def set_role(user, role) do
    user
    |> User.changeset_role(%{role: role})
    |> Repo.update()
  end

  def enabled_banks_select_options() do
    Enum.map(BankList.enabled(), fn {code, name} = _bank ->
      {name, code}
    end)
  end

  def bank_name(code) do
    Enum.find(
      BankList.all(),
      {"not_found", "BANK DENGAN CODE=#{code} TIDAK DITEMUKAN!!"},
      fn {c, _} ->
        c == code
      end
    )
    |> elem(1)
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

  def list_api_keys(user) do
    from(a in APIKey, where: a.user_id == ^user.id)
    |> Repo.all()
  end

  def get_api_key!(id) do
    APIKey
    |> Repo.get!(id)
  end

  def create_api_key(attrs) do
    %APIKey{}
    |> APIKey.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_api_key(api_key, attrs) do
    api_key
    |> APIKey.changeset(attrs)
    |> Repo.update()
  end

  def delete_api_key(api_key) do
    Repo.delete(api_key)
  end

  def change_api_key(api_key, attrs \\ %{}) do
    api_key
    |> APIKey.changeset(attrs)
  end

  def get_by_api_key(key) do
    key_hash = APIKey.hash(key)

    from(u in User,
      join: a in APIKey,
      on: u.id == a.user_id,
      where: a.key == ^key_hash,
      select: u
    )
    |> Repo.one()
  end
end
