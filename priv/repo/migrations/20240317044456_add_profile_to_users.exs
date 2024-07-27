defmodule App.Repo.Migrations.AddProfileToUsers do
  use Ecto.Migration

  @doc """
  Add new columns to `users` table.
  These columns are for branding purpose and display on user's profile or invoice.
  """

  def change do
    alter table(:users) do
      add :brand_name, :string, null: true
      add :brand_email, :string, null: true
      add :brand_phone, :string, null: true
      add :brand_logo, :string, null: true
      add :brand_website, :string, null: true
    end
  end
end
