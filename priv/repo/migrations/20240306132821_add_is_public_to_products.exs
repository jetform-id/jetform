defmodule App.Repo.Migrations.AddIsPublicToProducts do
  use Ecto.Migration

  @doc """
  Add `is_public` column to `products` table.

  If this column is `true`, the product will be displayed on the marketplace.
  """
  def change do
    alter table(:products) do
      add :is_public, :boolean, null: false, default: false
    end

    create index(:products, [:is_live, :is_public, :inserted_at])
  end
end
