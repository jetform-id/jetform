defmodule Workers.NotifyNewOrder do
  use Oban.Worker, queue: :default, max_attempts: 3
  require Logger
  alias App.Orders

  def create(%{status: :pending} = order) do
    %{id: order.id, status: order.status}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  def create(%{status: :free} = order) do
    %{id: order.id, status: order.status}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  def create(_order) do
    {:ok, :noop}
  end

  @impl true
  def perform(%{args: %{"id" => id, "status" => status}}) do
    case Orders.get_order(id) do
      nil ->
        Logger.warning("#{__MODULE__} warning: order=#{id} not found")

        :ok

      order ->
        send_email(order |> App.Repo.preload(:user), status)
    end
  end

  defp send_email(order, status) do
    base_url = AppWeb.Utils.base_url()

    status_text =
      case status do
        "pending" -> "(Menunggu Pembayaran)"
        "free" -> "(Gratis)"
      end

    invoice_text =
      case status do
        "pending" -> "Detail pembelian dan cara pembayaran bisa anda lihat di halaman berikut:"
        _ -> "Detail pembelian bisa anda lihat di halaman berikut:"
      end

    buyer_text = """
    Halo #{order.customer_name},

    Anda telah melakukan pembelian berikut:
    No. Invoice: ##{order.invoice_number}
    Produk: #{Orders.product_fullname(order)}
    Total: Rp. #{order.total}
    Status: #{order.status} #{status_text}

    #{invoice_text}
    #{base_url}/invoice/#{order.id}

    --
    Tim Snappy
    """

    user = order.user

    user_text = """
    Halo #{user.email},

    Terdapat pesanan baru atas produk anda:
    No. Invoice: ##{order.invoice_number}
    Produk: #{Orders.product_fullname(order)}
    Total: Rp. #{order.total}
    Status: #{order.status} #{status_text}

    --
    Tim Snappy
    """

    buyer_email =
      %{
        user: %{name: order.customer_name, email: order.customer_email},
        subject:
          "Detail pembelian anda ##{order.invoice_number} | #{Orders.product_fullname(order)}",
        text: buyer_text,
        html: nil
      }

    seller_email =
      %{
        user: %{name: "", email: user.email},
        subject: "Order Pending ##{order.invoice_number} | #{Orders.product_fullname(order)}",
        text: user_text,
        html: nil
      }

    case status do
      "pending" -> [buyer_email, seller_email]
      "free" -> [buyer_email]
    end
    |> Enum.map(&App.Mailer.cast/1)
    |> App.Mailer.deliver_many()
  end
end
