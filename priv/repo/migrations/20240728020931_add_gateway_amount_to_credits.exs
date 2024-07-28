defmodule App.Repo.Migrations.AddGatewayAmountToCredits do
  use Ecto.Migration

  def change do
    alter table(:credits) do
      add :gateway_amount, :integer, default: 0
    end
  end
end
