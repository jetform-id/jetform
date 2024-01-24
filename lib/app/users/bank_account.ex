defmodule App.Users.BankAccount do
  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(bank_name account_name account_number current_password)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bank_accounts" do
    field :bank_name, :string
    field :account_name, :string
    field :account_number, :string
    field :current_password, :string, virtual: true

    belongs_to :user, App.Users.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bank_account, attrs) do
    bank_account
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end

  def create_changeset(bank_account, attrs) do
    bank_account
    |> changeset(attrs)
    |> validate_user(attrs)
    |> validate_current_password()
  end

  def update_changeset(bank_account, attrs) do
    bank_account
    |> changeset(attrs)
    |> validate_current_password()
  end

  defp validate_user(changeset, attrs) do
    case Map.get(attrs, "user") do
      nil -> add_error(changeset, :user, "can't be blank")
      user -> put_assoc(changeset, :user, user)
    end
  end

  defp validate_current_password(changeset) do
    user = get_field(changeset, :user)
    password = get_field(changeset, :current_password)

    case App.Users.User.verify_password(user, password) do
      true -> changeset
      false -> add_error(changeset, :current_password, "is invalid")
    end
  end
end
