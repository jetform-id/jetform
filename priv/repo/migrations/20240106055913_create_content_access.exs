defmodule App.Repo.Migrations.CreateContentAccess do
  use Ecto.Migration

  @doc """
  Store buyer's access to contents.

  When order deleted, access will be deleted.
  No point keeping content accesses if the order is deleted.
  """
  def change do
    create table(:content_access, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :order_id, references(:orders, type: :uuid, on_delete: :delete_all), null: false
      add :valid_until, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:content_access, [:order_id])
  end
end
