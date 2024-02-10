defmodule App.Repo.Migrations.CreateOrdersContents do
  use Ecto.Migration

  @doc """
  Store relation between orders and contents.

  When order or content deleted, their relation will be deleted.
  No point to keep the relation if one of them is deleted.
  """
  def change do
    create table(:order_contents, primary_key: false) do
      add :order_id, references(:orders, type: :binary_id, on_delete: :delete_all)
      add :content_id, references(:contents, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:order_contents, [:order_id, :content_id])
  end
end
