defmodule App.Orders.OrderContent do
  use Ecto.Schema

  @primary_key false
  @foreign_key_type :binary_id
  schema "order_contents" do
    belongs_to :order, App.Orders.Order
    belongs_to :content, App.Contents.Content

    timestamps(type: :utc_datetime)
  end
end
