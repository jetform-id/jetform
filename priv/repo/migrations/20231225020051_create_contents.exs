defmodule App.Repo.Migrations.CreateContents do
  use Ecto.Migration

  @doc """
  Store product's contents.

  - When product deleted, content are kept but has no product_id.
  - When product variant deleted, content are kept but has no product_variant_id.
  - Content is soft-deleted so buyer can still access it even after it delted by seller.

  Above rules mean that content can be orphaned and should never be deleted using the app.
  """
  def change do
    create table(:contents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :product_id, references(:products, type: :binary_id, on_delete: :nilify_all)

      add :product_variant_id,
          references(:product_variants, type: :binary_id, on_delete: :nilify_all)

      add :type, :string, null: false
      add :name, :string, null: false
      add :text, :text
      add :file, :string
      # soft-delete
      add :deleted_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:contents, [:product_id, :product_variant_id])
    create index(:contents, [:deleted_at])
  end
end
