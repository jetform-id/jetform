defmodule App.Products do
  import Ecto.Query
  alias App.Repo
  alias App.Products.Product

  def list_products_by_user(user) do
    query = from(p in Product, where: p.user_id == ^user.id, order_by: [desc: p.inserted_at])
    query |> Repo.all()
  end

  def get_product(id) do
    Product
    |> Repo.get(id)
  end

  def change_product(product, attrs) do
    product
    |> Product.changeset(attrs)
  end

  def create_product(attrs) do
    %Product{}
    |> Product.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_product(product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  def delete_product(product) do
    Repo.delete(product)
  end
end
