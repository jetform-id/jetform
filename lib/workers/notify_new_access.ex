defmodule Workers.NotifyNewAccess do
  use Oban.Worker, queue: :default, max_attempts: 3
  require Logger
  alias App.Orders
  alias App.Contents

  @doc """
  Create a new job to notify user about their access to a product.
  """
  def create(nil), do: {:ok, :noop}

  def create(access) do
    %{id: access.id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  @impl true
  def perform(%{args: %{"id" => id}}) do
    case Contents.get_access(id) do
      nil ->
        Logger.warning("#{__MODULE__} warning: access=#{id} not found")

        :ok

      access ->
        send_email(access |> App.Repo.preload(:order))
    end
  end

  defp send_email(access) do
    order = access.order

    valid_until =
      access.valid_until
      |> Timex.to_datetime("Asia/Jakarta")
      |> Timex.format!("%d %B %Y %H:%M WIB", :strftime)

    base_url = AppWeb.Utils.base_url()

    text = """
    Halo #{order.customer_name},

    Berikut adalah link untuk mengakses '#{Orders.product_fullname(order)}':
    #{base_url}/access/#{access.id}

    PENTING: link di atas hanya berlaku sampai #{valid_until} (7 hari dari sekarang).
    Kami sarankan anda download semua file yang ada dan menyimpannya di tempat yang aman.

    Dan berikut detail order anda:
    #{base_url}/invoice/#{order.id}

    --
    Tim Snappy
    """

    %{
      user: %{name: order.customer_name, email: order.customer_email},
      subject: "Akses #{App.Orders.product_fullname(order)}",
      text: text,
      html: nil
    }
    |> App.Mailer.cast()
    |> App.Mailer.process_sync()
  end
end
