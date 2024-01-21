defmodule App.Repo.Migrations.CreateWithdrawals do
  use Ecto.Migration

  def change do
    create table(:withdrawals, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, null: false
      add :amount, :integer, null: false
      add :service_fee, :integer, default: 0
      add :admin_note, :text
      add :admin_transfer_prove, :string
      add :withdrawable_credits_until, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:withdrawals, [:user_id, :status, :inserted_at])
  end
end
