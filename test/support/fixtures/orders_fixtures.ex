defmodule App.OrdersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Orders` context.
  """

  @doc """
  Generate a order.
  """
  def order_fixture(attrs \\ %{}) do
    {:ok, order} =
      attrs
      |> Enum.into(%{
        discount_name: "some discount_name",
        discount_value: 42,
        product_id: "some product_id",
        product_name: "some product_name",
        product_variant_id: "some product_variant_id",
        product_variant_name: "some product_variant_name",
        sub_total: 42,
        total: 42,
        user_email: "some user_email",
        user_name: "some user_name",
        user_phone: "some user_phone"
      })
      |> App.Orders.create_order()

    order
  end
end
