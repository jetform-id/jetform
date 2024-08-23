defmodule App.Products.Image do
  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "product_images" do
    field :attachment, App.Products.ImageUploader.Type
    field :attachment_size_byte, :integer
    field :order, :integer

    belongs_to :product, App.Products.Product

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:attachment_size_byte, :order])
    |> validate_product(attrs)
  end

  def attachment_changeset(image, attrs) do
    cast_attachments(image, attrs, [:attachment], allow_paths: true)
  end

  defp validate_product(changeset, attrs) do
    case Map.get(attrs, "product") do
      nil ->
        add_error(changeset, :product, "can't be blank")

      product ->
        put_assoc(changeset, :product, product)
    end
  end
end
