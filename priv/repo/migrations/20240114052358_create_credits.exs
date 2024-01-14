defmodule App.Repo.Migrations.CreateCredits do
  use Ecto.Migration

  def change do
    create table(:credits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :order_id, references(:orders, type: :uuid, on_delete: :delete_all), null: false
      add :user_amount, :integer, default: 0
      add :system_amount, :integer, default: 0
      add :withdrawable_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:credits, [:order_id])
    create index(:credits, [:user_id, :withdrawable_at])
  end
end
