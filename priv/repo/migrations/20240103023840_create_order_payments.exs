defmodule App.Repo.Migrations.CreateOrderPayments do
  use Ecto.Migration

  def change do
    create table(:order_payments, primary_key: false) do
      add :id, :uuid, primary_key: true, null: false
      add :order_id, references(:orders, type: :uuid, on_delete: :delete_all), null: false
      add :payload, :text
      add :type, :string
      add :trx_id, :string
      add :trx_status, :string
      add :fraud_status, :string
      add :status_code, :string
      add :gross_amount, :float
      add :redirect_url, :text

      timestamps(type: :utc_datetime)
    end

    create index(:order_payments, [:order_id, :inserted_at])
  end
end
