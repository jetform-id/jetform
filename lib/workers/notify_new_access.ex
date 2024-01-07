defmodule Workers.NotifyNewAccess do
  use Oban.Worker, queue: :default, max_attempts: 3
  require Logger
  alias App.Orders
  alias App.Contents

  @doc """
  Create a new job to notify user about their access to a product.
  """
  def create(%{status: :paid} = order) do
    access_validity_days = Application.fetch_env!(:app, :access_validity_days)

    params = %{
      "order" => order,
      "valid_until" => Timex.shift(Timex.now(), days: access_validity_days)
    }

    case Contents.create_access(params) do
      {:ok, access} ->
        %{access_id: access.id}
        |> __MODULE__.new()
        |> Oban.insert()

      {:error, reason} ->
        Logger.error("#{__MODULE__} error: failed to create access, reason: #{inspect(reason)}")

        {:error, reason}
    end
  end

  def create(_order) do
    {:ok, :noop}
  end

  @impl true
  def perform(%{args: %{"access_id" => access_id}}) do
    case Contents.get_access(access_id) do
      nil ->
        Logger.warning("#{__MODULE__} warning: access=#{access_id} not found")

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
    Team Snappy
    """

    html = """
    <p>Halo <b>#{order.customer_name}</b>,</p>

    <p>Berikut adalah link untuk mengakses <b>#{Orders.product_fullname(order)}</b>:<br/>
    <a href="#{base_url}/access/#{access.id}" target="_blank">#{base_url}/access/#{access.id}</a>
    </p>

    <i><b style="color:red">PENTING</b>: link di atas hanya berlaku sampai <b>#{valid_until} (7 hari dari sekarang)</b>.
    Kami sarankan anda download semua file yang ada dan menyimpannya di tempat yang aman.</i>

    <p>Dan berikut detail order anda:<br/>
    <a href="#{base_url}/invoice/#{order.id}" target="_blank">#{base_url}/invoice/#{order.id}</a>
    </p>

    <p>--<br/>Team Snappy</p>
    """

    %{
      user: %{name: order.customer_name, email: order.customer_email},
      subject: "Akses #{App.Orders.product_fullname(order)}",
      text: text,
      html: html
    }
    |> App.Mailer.cast()
    |> App.Mailer.process_sync()
  end
end
