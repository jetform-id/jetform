defmodule AppWeb.API.Schemas do
  require OpenApiSpex
  alias OpenApiSpex.Schema

  defmodule FlopMeta do
    OpenApiSpex.schema(%{
      title: "PaginationMeta",
      description: "Metadata for pagination",
      type: :object,
      properties: %{
        total_pages: %Schema{
          type: :integer,
          description: "Total pages"
        },
        total_count: %Schema{
          type: :integer,
          description: "Total items"
        },
        current_page: %Schema{
          type: :integer,
          description: "Current page number"
        },
        next_page: %Schema{
          type: :integer,
          description: "Next page number"
        },
        previous_page: %Schema{
          type: :integer,
          description: "Previous page number"
        },
        page_size: %Schema{
          type: :integer,
          description: "Number of items per page"
        }
      }
    })
  end

  defmodule ProductCover do
    OpenApiSpex.schema(%{
      title: "ProductCover",
      description: "Product cover urls",
      type: :object,
      properties: %{
        thumb_url: %Schema{
          type: :string,
          description: "Product cover thumb url"
        },
        standard_url: %Schema{
          type: :string,
          description: "Product cover standard url"
        }
      }
    })
  end

  defmodule Product do
    OpenApiSpex.schema(%{
      title: "Product",
      description: "A single product",
      type: :object,
      properties: %{
        id: %Schema{
          type: :string,
          description: "Product ID",
          format: "uuid"
        },
        slug: %Schema{
          type: :string,
          description: "Product slug"
        },
        name: %Schema{
          type: :string,
          description: "Product name"
        },
        price: %Schema{
          type: :integer,
          description: "Product price"
        },
        description: %Schema{
          type: :string,
          description: "Product description"
        },
        is_live: %Schema{
          type: :boolean,
          description: "Product live status"
        },
        is_public: %Schema{
          type: :boolean,
          description: "Product public status"
        },
        cta: %Schema{
          type: :string,
          description: "Product CTA"
        },
        cta_text: %Schema{
          type: :string,
          description: "Product custom CTA"
        },
        details: %Schema{
          type: :object,
          description: "Product details"
        },
        user_id: %Schema{
          type: :string,
          description: "Product user ID",
          format: "uuid"
        },
        description_html: %Schema{
          type: :string,
          description: "Product description in HTML"
        },
        description_plain: %Schema{
          type: :string,
          description: "Product description in plain text"
        },
        cover: ProductCover,
        price_display: %Schema{
          type: :string,
          description: "Product price display"
        },
        checkout_url: %Schema{
          type: :string,
          description: "Product checkout page URL"
        },
        inserted_at: %Schema{
          type: :string,
          description: "Product inserted at",
          format: "date-time"
        },
        updated_at: %Schema{
          type: :string,
          description: "Product updated at",
          format: "date-time"
        }
      }
    })
  end

  defmodule ProductVariant do
    OpenApiSpex.schema(%{
      title: "Variant",
      description: "A single variant",
      type: :object,
      properties: %{
        id: %Schema{
          type: :string,
          description: "Variant ID",
          format: "uuid"
        },
        name: %Schema{
          type: :string,
          description: "Variant name"
        },
        descrition: %Schema{
          type: :string,
          description: "Variant description"
        },
        price: %Schema{
          type: :integer,
          description: "Variant price"
        },
        order: %Schema{
          type: :integer,
          description: "Variant ordering"
        },
        product_id: %Schema{
          type: :string,
          description: "Product ID",
          format: "uuid"
        },
        inserted_at: %Schema{
          type: :string,
          description: "Variant inserted at",
          format: "date-time"
        },
        updated_at: %Schema{
          type: :string,
          description: "Variant updated at",
          format: "date-time"
        }
      }
    })
  end

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

  defmodule ProductResponse do
    OpenApiSpex.schema(%{
      title: "ProductResponse",
      description: "Response schema for single product",
      type: :object,
      properties: %{
        data: Product
      }
    })
  end

  defmodule ProductsResponse do
    OpenApiSpex.schema(%{
      title: "ProductsResponse",
      description: "Response schema for multiple products",
      type: :object,
      properties: %{
        data: %Schema{
          type: :array,
          items: Product,
          description: "List of products"
        },
        meta: FlopMeta
      }
    })
  end

  defmodule ProductVariantsResponse do
    OpenApiSpex.schema(%{
      title: "ProductVariantsResponse",
      description: "Response schema for multiple product variants",
      type: :object,
      properties: %{
        data: %Schema{
          type: :array,
          items: ProductVariant,
          description: "List of product variants"
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
        },
        meta: FlopMeta
      }
    })
  end
end
