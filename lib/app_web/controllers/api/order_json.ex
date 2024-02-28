defmodule AppWeb.API.OrderJSON do
  alias App.Orders

  def index(%{orders: orders, meta: _meta, as_array: true}) do
    Enum.map(orders, &transform/1)
  end

  def index(%{orders: orders, meta: meta, as_array: _}) do
    %{data: Enum.map(orders, &transform/1), meta: transform_meta(meta)}
  end

  def show(%{order: order}), do: %{data: transform(order)}

  defp transform_meta(meta) do
    Map.take(meta, [
      :total_pages,
      :total_count,
      :current_page,
      :next_page,
      :previous_page,
      :page_size
    ])
  end

  defp transform(%Orders.Order{} = order) do
    Map.take(order, [
      :id,
      :user_id,
      :status,
      :invoice_number,
      :product_id,
      :product_name,
      :product_variant_id,
      :product_variant_name,
      :discount_name,
      :discount_value,
      :sub_total,
      :total,
      :payment_type,
      :service_fee,
      :customer_name,
      :customer_email,
      :customer_phone,
      :valid_until,
      :paid_at,
      :inserted_at,
      :updated_at
    ])
  end
end
