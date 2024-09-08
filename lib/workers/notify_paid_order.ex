defmodule Workers.NotifyPaidOrder do
  use Oban.Worker, queue: :default, max_attempts: 3
  require Logger
  alias App.Mailer
  alias App.Orders
  alias Workers.Utils

  def create(%{status: :paid} = order) do
    %{id: order.id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  def create(_order) do
    {:ok, :noop}
  end

  @impl true
  def perform(%{args: %{"id" => id}}) do
    case Orders.get_order(id) do
      nil ->
        Logger.warning("#{__MODULE__} warning: order=#{id} not found")

        :ok

      order ->
        send_email(order |> App.Repo.preload(:user))
    end
  end

  defp send_email(order) do
    user = order.user
    base_url = AppWeb.Utils.dashboard_url()

    buyer_text = """
    Halo #{order.customer_name},

    Pembayaran Anda berhasil:
    No. Invoice: ##{order.invoice_number}
    Produk: #{Orders.product_fullname(order)}
    Total: #{App.Utils.Commons.format_price(order.total)}
    Status: #{order.status} (LUNAS)

    *** PENTING ***
    Anda akan segera menerima email tentang cara mengakses ke produk yang anda beli.
    Apabila dalam 1 jam anda belum menerima email tersebut, silahkan hubungi kami dengan membalas email ini.

    Detail pembelian bisa anda lihat di halaman berikut:
    #{base_url}/invoices/#{order.id}

    #{Utils.email_signature(user)}
    """

    user_text = """
    Halo #{user.email},

    Pembelian atas produk Anda telah LUNAS:
    No. Invoice: #{order.invoice_number}
    Produk: #{Orders.product_fullname(order)}
    Harga: #{App.Utils.Commons.format_price(order.total)}
    Status: #{order.status} (LUNAS)

    Detail pembelian bisa anda lihat di halaman berikut:
    #{base_url}/invoices/#{order.id}
    """

    # Mailgun doesn't support `deliver_many` so we have to send them one by one
    [
      %{
        user: %{name: "", email: user.email},
        subject: "Order Lunas ##{order.invoice_number} | #{Orders.product_fullname(order)}",
        text: user_text,
        html: nil
      },
      %{
        user: %{name: order.customer_name, email: order.customer_email},
        subject:
          "Pembayaran berhasil ##{order.invoice_number} | #{Orders.product_fullname(order)}",
        text: buyer_text,
        html: nil
      }
    ]
    |> Enum.map(&Mailer.cast/1)
    |> Enum.each(&Mailer.process/1)

    :ok
  end
end
