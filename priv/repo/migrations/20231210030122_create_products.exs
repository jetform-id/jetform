defmodule App.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  @doc """
  Store user's products.

  When user deleted, all their products will be deleted.
  """
  def change do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :slug, :string, null: false
      add :price, :integer, null: false
      add :description, :text
      add :is_live, :boolean, null: false, default: false
      add :cta, :string, null: false
      add :cta_text, :string
      add :details, :jsonb
      add :cover, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:products, [:slug])
  end
end
