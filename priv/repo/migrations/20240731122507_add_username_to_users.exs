defmodule App.Repo.Migrations.AddUsernameToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :username, :string
    end

    create unique_index(:users, [:username])

    # remove product's [:slug] index and replace it with [:user_id, :slug] index
    # since product now accesible only under user's scope.
    # e.g: /username/product-slug
    drop unique_index(:products, [:slug])
    create unique_index(:products, [:user_id, :slug])
  end
end
