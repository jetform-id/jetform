defmodule App.Products do
  import Ecto.Query
  alias App.Repo
  alias App.Products.Product

  defdelegate cta_options, to: Product
  defdelegate cta_text(cta), to: Product
  defdelegate cta_custom?(cta), to: Product

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

  def cover_url(product, version, opts \\ []) do
    App.Products.ProductCover.url({product.cover, product}, version, opts)
  end

  def add_detail(product, %{changes: changes}) do
    # try to get details from changes, if not, get from product
    details =
      case Map.get(changes, :details) do
        nil -> product.details
        details -> details
      end

    id = DateTime.utc_now() |> DateTime.to_unix() |> Integer.to_string()

    details =
      Map.put(details, "items", details["items"] ++ [%{"id" => id, "key" => "", "value" => ""}])

    change_product(product, Map.put(changes, :details, details))
  end

  def delete_detail(product, %{changes: changes}, detail) do
    # try to get details from changes, if not, get from product
    details =
      case Map.get(changes, :details) do
        nil -> product.details
        details -> details
      end

    items =
      Enum.filter(details["items"], fn item ->
        item["id"] != detail["id"]
      end)

    details = Map.put(details, "items", items)
    change_product(product, Map.put(changes, :details, details))
  end

  def update_detail(product, %{changes: changes}, id, which, value) do
    # try to get details from changes, if not, get from product
    details =
      case Map.get(changes, :details) do
        nil -> product.details
        details -> details
      end

    items =
      Enum.map(details["items"], fn item ->
        if item["id"] == id do
          Map.put(item, which, value)
        else
          item
        end
      end)

    details = Map.put(details, "items", items)
    change_product(product, Map.put(changes, :details, details))
  end
end
