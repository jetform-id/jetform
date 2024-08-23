defmodule App.Repo.Migrations.AddTypeToProduct do
  use Ecto.Migration

  def change do
    create table(:product_images, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :product_id, references(:products, type: :binary_id, on_delete: :delete_all),
        null: false

      add :attachment, :string
      add :attachment_size_byte, :integer
      add :order, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    alter table(:products) do
      add :type, :string, null: false, default: "downloadable"
    end
  end
end
