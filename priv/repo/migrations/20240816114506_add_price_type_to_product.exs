defmodule App.Repo.Migrations.AddStatusToProductVariants do
  use Ecto.Migration

  def change do
    alter table(:products) do
      add :price_type, :string, null: false, default: "fixed"
    end

    alter table(:product_variants) do
      add :is_active, :boolean, null: false, default: true
    end
  end
end
