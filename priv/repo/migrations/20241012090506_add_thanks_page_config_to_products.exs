defmodule App.Repo.Migrations.AddThanksPageConfigToProducts do
  use Ecto.Migration

  def change do
    alter table(:products) do
      # we'll store the thanks page config as a map
      add :thanks_page_config, :map
    end

    alter table(:orders) do
      # when buyer create an order, we'll copy the thanks page config from the product
      add :thanks_page_config, :map
    end
  end
end
