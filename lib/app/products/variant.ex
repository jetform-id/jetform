defmodule App.Products.Variant do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(name price)a
  @optional_fields ~w(description quantity order)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "product_variants" do
    field :name, :string
    field :description, :string
    field :price, :integer
    field :order, :integer
    field :quantity, :integer

    belongs_to :product, App.Products.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(variant, attrs) do
    variant
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:price, greater_than_or_equal_to: 0)
  end

  def create_changeset(variant, attrs) do
    variant
    |> changeset(attrs)
    |> validate_product(attrs)
  end

  defp validate_product(changeset, attrs) do
    case Map.get(attrs, "product") do
      nil -> add_error(changeset, :product, "can't be blank")
      product -> put_assoc(changeset, :product, product)
    end
  end
end
