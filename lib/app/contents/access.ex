defmodule App.Contents.Access do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "content_access" do
    field :valid_until, :utc_datetime

    belongs_to :order, App.Orders.Order

    timestamps(type: :utc_datetime)
  end

  def is_valid?(access) do
    Timex.compare(Timex.now(), access.valid_until, :second) in [-1, 0]
  end

  @doc false
  def changeset(access, attrs) do
    access
    |> cast(attrs, [:valid_until])
    |> validate_required([:valid_until])
  end

  def create_changeset(access, attrs) do
    access
    |> changeset(attrs)
    |> validate_order(attrs)
  end

  defp validate_order(changeset, attrs) do
    case Map.get(attrs, "order") do
      nil ->
        add_error(changeset, :order, "can't be blank")

      order ->
        put_assoc(changeset, :order, order)
    end
  end
end
