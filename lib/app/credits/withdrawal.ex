defmodule App.Credits.Withdrawal do
  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending approved rejected cancelled finished)a
  @required_fields ~w(amount withdrawable_credits_until)a
  @optional_fields ~w(status service_fee admin_note admin_transfer_prove)a
  @attachment_fields ~w(admin_transfer_prove)a

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "withdrawals" do
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :amount, :integer
    field :service_fee, :integer
    field :admin_note, :string
    field :admin_transfer_prove, App.Credits.WithdrawalTransferProve.Type
    field :withdrawable_credits_until, :utc_datetime

    belongs_to :user, App.Users.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(payout, attrs) do
    payout
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_attachments(attrs, @attachment_fields, allow_paths: true)
    |> validate_required(@required_fields)
  end

  def create_changeset(withdrawal, attrs) do
    withdrawal
    |> changeset(attrs)
    |> validate_user(attrs)
  end

  defp validate_user(changeset, attrs) do
    case Map.get(attrs, "user") do
      nil -> add_error(changeset, :user, "can't be blank")
      user -> put_assoc(changeset, :user, user)
    end
  end
end
