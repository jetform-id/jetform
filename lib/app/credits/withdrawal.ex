defmodule App.Credits.Withdrawal do
  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  @derive {
    Flop.Schema,
    filterable: [:status], sortable: [:inserted_at]
  }

  @statuses ~w(pending submitted rejected cancelled success)a
  @required_fields ~w(amount withdrawal_timestamp recipient_bank_name recipient_bank_acc_name recipient_bank_acc_number)a
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
    field :withdrawal_timestamp, :utc_datetime
    field :recipient_bank_name, :string
    field :recipient_bank_acc_name, :string
    field :recipient_bank_acc_number, :string
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
