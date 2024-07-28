defmodule App.Repo.Migrations.AddFeeToOrderPayments do
  use Ecto.Migration

  def change do
    alter table(:order_payments) do
      add :fee, :integer, default: 0
    end
  end
end
