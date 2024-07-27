defmodule AppWeb.API.ProductJSON do
  use AppWeb, :verified_routes
  alias App.Products

  def index(%{products: products, meta: _meta, as_array: true}) do
    Enum.map(products, &transform/1)
  end

  def index(%{products: products, meta: meta, as_array: _}) do
    %{data: Enum.map(products, &transform/1), meta: transform_meta(meta)}
  end

  def show(%{product: product}) do
    %{data: transform(product)}
  end

  def list_variants(%{variants: variants, as_array: true}) do
    Enum.map(variants, &transform_variant/1)
  end

  def list_variants(%{variants: variants, as_array: _}) do
    %{data: Enum.map(variants, &transform_variant/1)}
  end

  defp transform_meta(meta) do
    Map.take(meta, [
      :total_pages,
      :total_count,
      :current_page,
      :next_page,
      :previous_page,
      :page_size
    ])
  end

  defp transform(%Products.Product{} = product) do
    cover = %{
      thumb_url: Products.cover_url(product, :thumb),
      standard_url: Products.cover_url(product, :standard)
    }

    Map.take(product, [
      :id,
      :slug,
      :name,
      :price,
      :is_live,
      :is_public,
      :cta,
      :cta_text,
      :details,
      :user_id,
      :inserted_at,
      :updated_at
    ])
    |> Map.put(:description_html, product.description)
    |> Map.put(:description_plain, HtmlSanitizeEx.strip_tags(product.description || ""))
    |> Map.put(:cover, cover)
    |> Map.put(:price_display, App.Products.price_display(product))
    |> Map.put(:checkout_url, AppWeb.Utils.base_url() <> ~p"/p/#{product.slug}")
  end

  defp transform_variant(%Products.Variant{} = variant) do
    Map.take(variant, [
      :id,
      :name,
      :descrition,
      :price,
      :order,
      :product_id,
      :inserted_at,
      :updated_at
    ])
  end
end
