defmodule App.Products.Version do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(name)a
  @optional_fields ~w(price description quantity order)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "product_versions" do
    field :name, :string
    field :description, :string
    field :price, :integer
    field :order, :integer
    field :quantity, :integer

    belongs_to :product, App.Products.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(version, attrs) do
    version
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end

  def create_changeset(version, attrs) do
    version
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
