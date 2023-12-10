defmodule App.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  use Pow.Ecto.Schema

  use Pow.Extension.Ecto.Schema,
    extensions: [PowResetPassword, PowEmailConfirmation]

  alias App.Utils.ReservedWords

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    pow_user_fields()

    field :timezone, :string, default: "Asia/Jakarta"
    field :username, :string

    has_one :bank_account, App.Users.BankAccount
    has_many :products, App.Products.Product

    timestamps(type: :utc_datetime)
  end

  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> pow_extension_changeset(attrs)
    |> profile_changeset(attrs)
  end

  defp profile_changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> cast(attrs, [:timezone, :username])
    |> validate_username()
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_length(:username, min: 4, max: 20)
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/)
    |> validate_reserved_words(:username)
    |> unsafe_validate_unique(:username, App.Repo)
    |> unique_constraint(:username)
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
