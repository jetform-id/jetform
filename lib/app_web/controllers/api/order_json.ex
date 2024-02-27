defmodule AppWeb.API.OrderJSON do
  alias App.Orders

  def index(%{orders: orders, meta: meta}) do
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
    %{
      id: order.id,
      user_id: order.user_id,
      status: order.status,
      invoice_number: order.invoice_number,
      product_id: order.product_id,
      product_name: order.product_name,
      product_variant_id: order.product_variant_id,
      product_variant_name: order.product_variant_name,
      discount_name: order.discount_name,
      discount_value: order.discount_value,
      sub_total: order.sub_total,
      total: order.total,
      payment_type: order.payment_type,
      service_fee: order.service_fee,
      customer_name: order.customer_name,
      customer_email: order.customer_email,
      customer_phone: order.customer_phone,
      valid_until: order.valid_until,
      paid_at: order.paid_at,
      inserted_at: order.inserted_at,
      updated_at: order.updated_at
    }
  end
end
