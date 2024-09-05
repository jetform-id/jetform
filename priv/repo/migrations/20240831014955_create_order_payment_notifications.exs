defmodule App.Repo.Migrations.CreateOrderPaymentNotifications do
  use Ecto.Migration

  def change do
    create table(:order_payment_notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :provider, :string
      add :payment_id, references(:order_payments, type: :binary_id, on_delete: :nothing)
      add :body_params, :map
      add :path_params, :map
      add :query_params, :map
      add :req_headers, :map
      add :req_cookies, :map
      add :request_path, :string
      add :request_method, :string
      add :remote_ip, :string
      add :host, :string
      add :port, :integer
      timestamps(type: :utc_datetime)
    end
  end
end
