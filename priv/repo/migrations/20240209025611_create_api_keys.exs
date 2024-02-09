defmodule App.Repo.Migrations.CreateApiKeys do
  use Ecto.Migration

  def change do
    create table(:api_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :key, :string, null: false
      add :masked_key, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:api_keys, [:key])
    create index(:api_keys, [:user_id])
  end
end
