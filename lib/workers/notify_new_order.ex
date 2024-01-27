defmodule Workers.NotifyNewOrder do
  use Oban.Worker, queue: :default, max_attempts: 3
  require Logger
  alias App.Orders

  def create(order) do
    %{id: order.id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  @impl true
  def perform(%{args: %{"id" => id}}) do
    case Orders.get_order(id) do
      nil ->
        Logger.warning("#{__MODULE__} warning: order=#{id} not found")

        :ok

      order ->
        send_email(order)
    end
  end

  defp send_email(order) do
    base_url = AppWeb.Utils.base_url()

    text = """
    Halo #{order.customer_name},

    Anda telah melakukan pembelian berikut:
    Produk: #{Orders.product_fullname(order)}
    Harga: Rp. #{order.total}
    No. Invoice: #{order.invoice_number}

    Detail pembelian dan cara pembayaran bisa anda lihat di halaman berikut:
    #{base_url}/invoice/#{order.id}

    --
    Tim Snappy
    """

    %{
      user: %{name: order.customer_name, email: order.customer_email},
      subject: "Detail pembelian anda ##{order.invoice_number}",
      text: text,
      html: nil
    }
    |> App.Mailer.cast()
    |> App.Mailer.process_sync()
  end
end
