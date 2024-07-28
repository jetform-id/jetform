defmodule App.Repo.Migrations.AddGatewayFeeToOrders do
  use Ecto.Migration

  def change do
    alter table(:orders) do
      add :gateway_fee, :integer, default: 0
    end
  end
end
