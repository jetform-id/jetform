defmodule AppWeb.API.Schemas do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  defmodule Order do
    OpenApiSpex.schema(%{
      title: "Order",
      description: "A single order",
      type: :object,
      properties: %{
        id: %Schema{
          type: :string,
          description: "Order ID",
          format: "uuid"
        },
        user_id: %Schema{
          type: :string,
          description: "User ID",
          format: "uuid"
        },
        status: %Schema{
          type: :string,
          description: "Order status"
        },
        invoice_number: %Schema{
          type: :string,
          description: "Invoice number"
        },
        product_id: %Schema{
          type: :string,
          description: "Product ID",
          format: "uuid"
        },
        product_name: %Schema{
          type: :string,
          description: "Product name"
        },
        product_variant_id: %Schema{
          type: :string,
          description: "Product variant ID",
          format: "uuid"
        },
        product_variant_name: %Schema{
          type: :string,
          description: "Product variant name"
        },
        discount_name: %Schema{
          type: :string,
          description: "Discount name"
        },
        discount_value: %Schema{
          type: :integer,
          description: "Discount value"
        },
        sub_total: %Schema{
          type: :integer,
          description: "Order sub-total"
        },
        total: %Schema{
          type: :integer,
          description: "Order total"
        },
        payment_type: %Schema{
          type: :string,
          description: "Payment type"
        },
        service_fee: %Schema{
          type: :integer,
          description: "Service fee"
        },
        customer_name: %Schema{
          type: :string,
          description: "Customer name"
        },
        customer_email: %Schema{
          type: :string,
          description: "Customer email",
          format: "email"
        },
        customer_phone: %Schema{
          type: :string,
          description: "Customer phone"
        },
        valid_until: %Schema{
          type: :string,
          description: "Order valid until",
          format: "date-time"
        },
        paid_at: %Schema{
          type: :string,
          description: "Order paid at",
          format: "date-time"
        },
        inserted_at: %Schema{
          type: :string,
          description: "Order inserted at",
          format: "date-time"
        },
        updated_at: %Schema{
          type: :string,
          description: "Order updated at",
          format: "date-time"
        }
      }
    })
  end

  defmodule OrderResponse do
    OpenApiSpex.schema(%{
      title: "OrderResponse",
      description: "Response schema for single order",
      type: :object,
      properties: %{
        data: Order
      }
    })
  end

  defmodule OrdersResponse do
    OpenApiSpex.schema(%{
      title: "OrdersResponse",
      description: "Response schema for multiple orders",
      type: :object,
      properties: %{
        data: %Schema{
          type: :array,
          items: Order,
          description: "List of orders"
        }
      }
    })
  end
end
