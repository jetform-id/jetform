defmodule App.OrdersTest do
  use App.DataCase

  alias App.Orders

  describe "orders" do
    alias App.Orders.Order

    import App.OrdersFixtures

    @invalid_attrs %{total: nil, user_name: nil, user_email: nil, user_phone: nil, product_id: nil, product_name: nil, product_variant_id: nil, product_variant_name: nil, discount_name: nil, discount_value: nil, sub_total: nil}

    test "list_orders/0 returns all orders" do
      order = order_fixture()
      assert Orders.list_orders() == [order]
    end

    test "get_order!/1 returns the order with given id" do
      order = order_fixture()
      assert Orders.get_order!(order.id) == order
    end

    test "create_order/1 with valid data creates a order" do
      valid_attrs = %{total: 42, user_name: "some user_name", user_email: "some user_email", user_phone: "some user_phone", product_id: "some product_id", product_name: "some product_name", product_variant_id: "some product_variant_id", product_variant_name: "some product_variant_name", discount_name: "some discount_name", discount_value: 42, sub_total: 42}

      assert {:ok, %Order{} = order} = Orders.create_order(valid_attrs)
      assert order.total == 42
      assert order.user_name == "some user_name"
      assert order.user_email == "some user_email"
      assert order.user_phone == "some user_phone"
      assert order.product_id == "some product_id"
      assert order.product_name == "some product_name"
      assert order.product_variant_id == "some product_variant_id"
      assert order.product_variant_name == "some product_variant_name"
      assert order.discount_name == "some discount_name"
      assert order.discount_value == 42
      assert order.sub_total == 42
    end

    test "create_order/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Orders.create_order(@invalid_attrs)
    end

    test "update_order/2 with valid data updates the order" do
      order = order_fixture()
      update_attrs = %{total: 43, user_name: "some updated user_name", user_email: "some updated user_email", user_phone: "some updated user_phone", product_id: "some updated product_id", product_name: "some updated product_name", product_variant_id: "some updated product_variant_id", product_variant_name: "some updated product_variant_name", discount_name: "some updated discount_name", discount_value: 43, sub_total: 43}

      assert {:ok, %Order{} = order} = Orders.update_order(order, update_attrs)
      assert order.total == 43
      assert order.user_name == "some updated user_name"
      assert order.user_email == "some updated user_email"
      assert order.user_phone == "some updated user_phone"
      assert order.product_id == "some updated product_id"
      assert order.product_name == "some updated product_name"
      assert order.product_variant_id == "some updated product_variant_id"
      assert order.product_variant_name == "some updated product_variant_name"
      assert order.discount_name == "some updated discount_name"
      assert order.discount_value == 43
      assert order.sub_total == 43
    end

    test "update_order/2 with invalid data returns error changeset" do
      order = order_fixture()
      assert {:error, %Ecto.Changeset{}} = Orders.update_order(order, @invalid_attrs)
      assert order == Orders.get_order!(order.id)
    end

    test "delete_order/1 deletes the order" do
      order = order_fixture()
      assert {:ok, %Order{}} = Orders.delete_order(order)
      assert_raise Ecto.NoResultsError, fn -> Orders.get_order!(order.id) end
    end

    test "change_order/1 returns a order changeset" do
      order = order_fixture()
      assert %Ecto.Changeset{} = Orders.change_order(order)
    end
  end
end
