defmodule AppWeb.ProductController do
  use AppWeb, :controller
  alias App.Products

  def index(conn, _params) do
    products = Products.list_products_by_user(conn.assigns.current_user)
    render(conn, :index, products: products)
  end

  def new(conn, _params) do
    changeset = Products.change_product(%Products.Product{}, %{})
    render(conn, :new, changeset: changeset, action: ~p"/products")
  end

  def create(conn, %{"product" => product_params}) do
    user = conn.assigns.current_user
    product_params = Map.put(product_params, "user", user)

    case Products.create_product(product_params) do
      {:ok, product} ->
        conn
        |> put_flash(:info, "Product created successfully.")
        |> redirect(to: ~p"/products/#{product.id}/edit")

      {:error, changeset} ->
        render(conn, :new, changeset: changeset, action: ~p"/products")
    end
  end

  def edit(conn, %{"id" => id}) do
    case Products.get_product(id) do
      nil ->
        conn
        |> put_flash(:error, "Product not found.")
        |> redirect(to: ~p"/products")

      product ->
        changeset = Products.change_product(product, %{})
        render(conn, :edit, changeset: changeset, action: ~p"/products/#{id}")
    end
  end

  def update(conn, %{"id" => id, "product" => product_params}) do
    case Products.get_product(id) do
      nil ->
        conn
        |> put_flash(:error, "Product not found.")
        |> redirect(to: ~p"/products")

      product ->
        case Products.update_product(product, product_params) do
          {:ok, product} ->
            conn
            |> put_flash(:info, "Product updated successfully.")
            |> redirect(to: ~p"/products/#{product.id}/edit")

          {:error, changeset} ->
            render(conn, :edit, changeset: changeset, action: ~p"/products/#{product.id}")
        end
    end
  end

  def delete(conn, %{"id" => id}) do
    case Products.get_product(id) do
      nil ->
        conn
        |> put_flash(:error, "Product not found.")
        |> redirect(to: ~p"/products")

      product ->
        Products.delete_product(product)

        conn
        |> put_flash(:info, "Product deleted successfully.")
        |> redirect(to: ~p"/products")
    end
  end
end
