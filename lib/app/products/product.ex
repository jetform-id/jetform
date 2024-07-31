defmodule App.Products.Product do
  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset
  alias App.Utils.ReservedWords

  @derive {
    Flop.Schema,
    filterable: [:is_live, :is_public], sortable: [:inserted_at]
  }

  @required_fields ~w(name slug price cta)a
  @optional_fields ~w(is_live is_public description cta_text details)a
  @cta_enums ~w(buy buy_now get_now free_download i_want_it custom)a
  @ctas [
    {"Beli", :buy},
    {"Beli Sekarang", :buy_now},
    {"Dapatkan Sekarang", :get_now},
    {"Download Gratis", :free_download},
    {"Saya Mau", :i_want_it},
    {"Custom...", :custom}
  ]

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "products" do
    field :name, :string
    field :slug, :string
    field :price, :integer, default: 0
    field :description, :string
    field :is_live, :boolean, default: false
    field :is_public, :boolean, default: false

    field :cta, Ecto.Enum,
      values: @cta_enums,
      default: :buy

    field :cta_text, :string
    field :details, :map, default: %{"items" => []}
    field :cover, App.Products.ProductCover.Type

    belongs_to :user, App.Users.User
    has_many :variants, App.Products.Variant
    has_many :orders, App.Orders.Order
    has_many :contents, App.Contents.Content

    timestamps(type: :utc_datetime)
  end

  def cta_options() do
    @ctas
  end

  def cta_text(cta) do
    @ctas
    |> Enum.reduce(%{}, fn {value, text}, acc -> Map.put(acc, text, value) end)
    |> Map.fetch!(cta)
  end

  def cta_custom?(cta) do
    cta == :custom
  end

  def has_details?(product) do
    !Enum.empty?(Map.get(product.details, "items", %{}))
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_length(:name, max: 50, message: "maksimum %{count} karakter")
    |> cast_attachments(attrs, [:cover], allow_paths: true)
    |> validate_required(@required_fields)
    |> validate_number(:price, greater_than_or_equal_to: 0)
    |> validate_slug()
  end

  def create_changeset(product, attrs) do
    product
    |> changeset(attrs)
    |> validate_user(attrs)
  end

  defp validate_slug(changeset) do
    changeset
    |> validate_length(:slug, min: 3, max: 150)
    |> validate_format(:slug, ~r/^[a-zA-Z0-9_\-]+$/)
    |> validate_reserved_words(:slug)
    |> unsafe_validate_unique([:user_id, :slug], App.Repo)
    |> unique_constraint([:user_id, :slug])
  end

  defp validate_user(changeset, attrs) do
    case Map.get(attrs, "user") do
      nil -> add_error(changeset, :user, "can't be blank")
      user -> put_assoc(changeset, :user, user)
    end
  end

  defp validate_reserved_words(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if ReservedWords.is_reserved?(value) do
        [{field, "is reserved"}]
      else
        []
      end
    end)
  end
end
