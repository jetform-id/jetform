defmodule App.Repo.Migrations.AddProviderToOrderPayments do
  use Ecto.Migration

  def up do
    alter table(:orders) do
      add :cancellation_reason, :text
    end

    alter table(:order_payments) do
      add :provider, :string
      add :create_transaction_response, :map
      add :get_transaction_response, :map
      add :notification_payload, :map
      add :cancellation_reason, :text
      remove :payload
    end
  end

  def down do
    alter table(:orders) do
      remove :cancellation_reason
    end

    alter table(:order_payments) do
      remove :provider
      remove :create_transaction_response
      remove :get_transaction_response
      remove :notification_payload
      remove :cancellation_reason
      add :payload, :text
    end
  end
end
