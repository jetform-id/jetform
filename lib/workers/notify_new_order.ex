defmodule Workers.NotifyNewOrder do
  use Oban.Worker, queue: :default, max_attempts: 3
  require Logger
  alias App.Orders

  def create(order) do
    %{order_id: order.id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  @impl true
  def perform(%{args: %{"order_id" => order_id}}) do
    case Orders.get_order(order_id) do
      nil ->
        Logger.warning("#{__MODULE__} warning: order=#{order_id} not found")

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

    Detail pembelian bisa anda lihat di halaman berikut:
    #{base_url}/invoice/#{order.id}

    --
    Team Snappy
    """

    html = """
    <p>Halo <b>#{order.customer_name}</b>,</p>

    <p>Anda telah melakukan pembelian berikut:</p>
    <p>
    Produk: <b>#{Orders.product_fullname(order)}</b><br/>
    Harga: <b>Rp. #{order.total}</b><br/>
    No. Invoice: <b>#{order.invoice_number}</b>
    </p>

    <p>Detail pembelian bisa anda lihat di halaman berikut:<br/>
    <a href="#{base_url}/invoice/#{order.id}" target="_blank">#{base_url}/invoice/#{order.id}</a>
    </p>

    <p>--<br/>Team Snappy</p>
    """

    %{
      user: %{name: order.customer_name, email: order.customer_email},
      subject: "Detail pembelian anda ##{order.invoice_number}",
      text: text,
      html: html
    }
    |> App.Mailer.cast()
    |> App.Mailer.process_sync()
  end
end
