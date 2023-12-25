defmodule App.Repo.Migrations.CreateContents do
  use Ecto.Migration

  def change do
    create table(:contents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:products, type: :binary_id)
      add :product_variant_id, references(:product_variants, type: :binary_id)
      add :type, :string, null: false
      add :name, :string, null: false
      add :text, :text
      add :file, :string
      add :is_deleted, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:contents, [:product_id, :product_variant_id])
    create index(:contents, [:is_deleted])
  end
end
