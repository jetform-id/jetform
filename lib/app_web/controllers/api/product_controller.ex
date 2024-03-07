defmodule AppWeb.API.ProductController do
  use AppWeb, :controller
  use OpenApiSpex.ControllerSpecs

  alias App.Products
  alias AppWeb.API.{Schemas, Utils}

  @max_page_size 20

  operation(:index,
    summary: "List products",
    parameters: [
      is_live: [in: :query, type: :string, description: "Filter by is_live status"],
      is_public: [in: :query, type: :string, description: "Filter by is_public status"],
      page: [in: :query, type: :integer, description: "Page number"],
      limit: [in: :query, type: :integer, description: "Page size (max. 20)"]
    ],
    responses: [
      ok: {"Product list", "application/json", Schemas.ProductsResponse}
    ]
  )

  def index(%{assigns: %{current_user: user}} = conn, params) do
    # this is to support API clients that expect an array e.g Zapier
    as_array = params["as_array"] == "true"

    filters =
      []
      |> Utils.maybe_put_boolean_filter(params, "is_live")
      |> Utils.maybe_put_boolean_filter(params, "is_public")

    query = %{
      order_by: [:inserted_at],
      order_directions: [:desc],
      page_size: Utils.set_limit(params, "limit", @max_page_size),
      page: Map.get(params, "page", "1"),
      filters: filters
    }

    {products, meta} = Products.list_products_by_user!(user, query)
    render(conn, :index, products: products, meta: meta, as_array: as_array)
  end

  operation(:show,
    summary: "Show product",
    parameters: [
      id: [in: :path, type: :string, description: "Product ID"]
    ],
    responses: [
      ok: {"Product", "application/json", Schemas.ProductResponse}
    ]
  )

  def show(conn, %{"id" => id}) do
    product = Products.get_product!(id)
    render(conn, :show, product: product)
  end

  operation(:list_variants,
    summary: "List product variants",
    parameters: [
      id: [in: :path, type: :string, description: "Product ID"]
    ],
    responses: [
      ok: {"Product variants", "application/json", Schemas.ProductVariantsResponse}
    ]
  )

  def list_variants(conn, %{"id" => product_id} = params) do
    # this is to support API clients that expect an array e.g Zapier
    as_array = params["as_array"] == "true"

    product = Products.get_product!(product_id)
    variants = Products.list_variants_by_product(product)
    render(conn, :list_variants, variants: variants, as_array: as_array)
  end
end
