defmodule App.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  @doc """
  Store orders.

  - When user deleted, order are kept but has no user_id.
  - When product deleted, order are kept but has no product_id.
  - When product variant deleted, order are kept but has no product_variant_id.

  Above rules mean that order can be orphaned and should never be deleted using the app.
  """
  def change do
    create table(:orders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)
      add :customer_name, :string, null: false
      add :customer_email, :string, null: false
      add :customer_phone, :string
      add :product_id, references(:products, type: :binary_id, on_delete: :nilify_all)
      add :product_name, :string

      add :product_variant_id,
          references(:product_variants, type: :binary_id, on_delete: :nilify_all)

      add :product_variant_name, :string
      add :discount_name, :string
      add :discount_value, :integer, default: 0
      add :sub_total, :integer, default: 0
      add :total, :integer, default: 0
      add :valid_until, :utc_datetime
      add :invoice_number, :string, null: false
      add :status, :string, null: false
      add :payment_type, :string
      add :paid_at, :utc_datetime
      add :service_fee, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:orders, [:invoice_number])
    create index(:orders, [:customer_email])
    create index(:orders, [:user_id, :product_id, :product_variant_id])
  end
end
