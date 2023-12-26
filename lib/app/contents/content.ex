defmodule App.Contents.Content do
  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(type name)a
  @optional_fields ~w(text is_deleted)a
  @attachment_fields ~w(file)a
  @types ~w(text file)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "contents" do
    field :type, Ecto.Enum, values: @types
    field :name, :string
    field :text, :string
    field :file, App.Contents.ContentFile.Type
    field :is_deleted, :boolean, default: false

    belongs_to :product, App.Products.Product
    belongs_to :product_variant, App.Products.Variant

    many_to_many :orders, App.Orders.Order,
      join_through: App.Orders.OrderContent,
      on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def is_empty?(content) do
    case content.type do
      :text -> String.trim(content.text || "") == ""
      :file -> content.file == nil
    end
  end

  @doc false
  def changeset(content, attrs) do
    content
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_attachments(attrs, @attachment_fields, allow_paths: true)
    |> validate_required(@required_fields)
  end

  def create_changeset(content, attrs) do
    content
    |> changeset(attrs)
    |> validate_product(attrs)
    |> validate_product_variant(attrs)
  end

  defp validate_product(changeset, attrs) do
    case Map.get(attrs, "product") do
      nil ->
        add_error(changeset, :product, "can't be blank")

      product ->
        put_assoc(changeset, :product, product)
    end
  end

  defp validate_product_variant(changeset, attrs) do
    case Map.get(attrs, "product_variant") do
      nil ->
        changeset

      variant ->
        put_assoc(changeset, :product_variant, variant)
    end
  end
end
