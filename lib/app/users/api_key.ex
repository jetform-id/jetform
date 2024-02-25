defmodule App.Users.APIKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "api_keys" do
    field :name, :string
    field :key, :string
    field :masked_key, :string

    belongs_to :user, App.Users.User

    timestamps(type: :utc_datetime)
  end

  def hash(key) do
    :crypto.hash(:sha256, key) |> Base.encode16(case: :lower)
  end

  @doc false
  def changeset(api_key, attrs) do
    api_key
    |> cast(attrs, [:name, :key])
    |> validate_required([:name, :key])
  end

  def create_changeset(api_key, attrs) do
    api_key
    |> changeset(attrs)
    |> hash_key()
    |> unsafe_validate_unique(:key, App.Repo)
    |> unique_constraint(:key)
    |> validate_user(attrs)
  end

  defp hash_key(changeset) do
    key = get_change(changeset, :key)
    prefix = String.slice(key, 0..2)
    rest = String.slice(key, 3..-1) |> String.replace(~r/./, "*")

    changeset
    |> put_change(:key, hash(key))
    |> put_change(:masked_key, prefix <> rest)
  end

  defp validate_user(changeset, attrs) do
    case Map.get(attrs, "user") do
      nil -> add_error(changeset, :user, "can't be blank")
      user -> put_assoc(changeset, :user, user)
    end
  end
end
