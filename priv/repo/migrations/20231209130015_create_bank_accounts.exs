defmodule App.Repo.Migrations.CreateBankAccounts do
  use Ecto.Migration

  @doc """
  Store user's bank accounts.

  When user deleted, all their bank accounts will be deleted.
  """
  def change do
    create table(:bank_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :bank_name, :string, null: false
      add :account_number, :string, null: false
      add :account_name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:bank_accounts, [:user_id])
  end
end
