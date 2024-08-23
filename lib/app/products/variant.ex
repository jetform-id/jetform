defmodule App.Products.Variant do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(name price is_active)a
  @optional_fields ~w(description order)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "product_variants" do
    field :name, :string
    field :description, :string
    field :price, :integer
    field :order, :integer
    field :is_active, :boolean, default: true

    belongs_to :product, App.Products.Product
    has_many :orders, App.Orders.Order, foreign_key: :product_variant_id
    has_many :contents, App.Contents.Content, foreign_key: :product_variant_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(variant, attrs) do
    variant
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:name, max: 50, message: "maksimum %{count} karakter")
    |> validate_price()
  end

  def create_changeset(variant, attrs) do
    variant
    |> changeset(attrs)
    |> validate_product(attrs)
  end

  defp validate_price(changeset) do
    min_price = Application.get_env(:app, :minimum_price)
    price = get_field(changeset, :price)

    cond do
      price == 0 -> changeset
      price < min_price -> add_error(changeset, :price, "Minimum Rp. #{min_price}")
      true -> changeset
    end
  end

  defp validate_product(changeset, attrs) do
    case Map.get(attrs, "product") do
      nil -> add_error(changeset, :product, "can't be blank")
      product -> put_assoc(changeset, :product, product)
    end
  end
end
