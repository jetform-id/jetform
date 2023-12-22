defmodule App.Repo.Migrations.CreateProductVersions do
  use Ecto.Migration

  def change do
    create table(:product_versions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :product_id, references(:products, type: :binary_id, on_delete: :delete_all),
        null: false

      add :name, :string, null: false
      add :price, :integer
      add :description, :string
      add :quantity, :integer
      add :order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end
  end
end
