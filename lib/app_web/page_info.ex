defmodule AppWeb.PageInfo do
  use AppWeb, :verified_routes
  alias App.Products

  @enforce_keys [:title, :description, :image, :url]

  defstruct [
    :title,
    :description,
    :image,
    :url,
    type: "website"
  ]

  def new(%Products.Product{} = product) do
    cleaned_desc =
      HtmlSanitizeEx.strip_tags(product.description || "")
      |> String.slice(0..150)

    %__MODULE__{
      type: "product",
      title: product.name,
      description: cleaned_desc <> "...",
      image: Products.cover_url(product, :standard),
      url: AppWeb.Utils.product_url(product)
    }
  end
end
