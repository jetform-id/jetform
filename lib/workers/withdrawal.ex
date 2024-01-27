defmodule Workers.Withdrawal do
  use Oban.Worker, queue: :default, max_attempts: 3
  require Logger
  alias App.Users
  alias App.Credits

  def notify_withdrawal_confirmation(withdrawal) do
    %{action: "notify_withdrawal_confirmation", id: withdrawal.id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  def notify_withdrawal_confirmed(withdrawal) do
    %{action: "notify_withdrawal_confirmed", id: withdrawal.id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  def notify_withdrawal_cancelation(withdrawal) do
    %{action: "notify_withdrawal_cancelation", id: withdrawal.id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  @impl true
  def perform(%{args: %{"action" => "notify_withdrawal_confirmation", "id" => id}}) do
    case Credits.get_withdrawal(id) do
      nil ->
        Logger.warning("#{__MODULE__} warning: withdrawal=#{id} not found")

        :ok

      withdrawal ->
        send_confirmation_email(withdrawal)
    end
  end

  @impl true
  def perform(%{args: %{"action" => "notify_withdrawal_confirmed", "id" => id}}) do
    case Credits.get_withdrawal(id) do
      nil ->
        Logger.warning("#{__MODULE__} warning: withdrawal=#{id} not found")

        :ok

      withdrawal ->
        send_confirmed_email(withdrawal)
    end
  end

  @impl true
  def perform(%{args: %{"action" => "notify_withdrawal_cancelation", "id" => id}}) do
    case Credits.get_withdrawal(id) do
      nil ->
        Logger.warning("#{__MODULE__} warning: withdrawal=#{id} not found")

        :ok

      withdrawal ->
        send_cancelation_email(withdrawal)
    end
  end

  defp withdrawal_detail(withdrawal) do
    user = withdrawal.user

    withdrawal_time =
      withdrawal.withdrawal_timestamp
      |> Timex.to_datetime(user.timezone)
      |> Timex.format!("%d-%m-%Y %H:%M " <> Users.tz_label(user.timezone), :strftime)

    """
    Tanggal & waktu penarikan: #{withdrawal_time}
    Jumlah penarikan: Rp. #{withdrawal.amount}
    Biaya admin: Rp. #{withdrawal.service_fee}
    Jumlah diterima: Rp. #{withdrawal.amount - withdrawal.service_fee}
    Akun Bank penerima: #{withdrawal.recipient_bank_name} / #{withdrawal.recipient_bank_acc_name} / #{withdrawal.recipient_bank_acc_number}
    """
  end

  defp send_confirmation_email(withdrawal) do
    withdrawal = App.Repo.preload(withdrawal, :user)
    user = withdrawal.user
    base_url = AppWeb.Utils.base_url()
    token = Credits.create_withdrawal_confirmation_token(withdrawal)

    text = """
    Halo #{user.email},

    Anda MENGAJUKAN penarikan dana sebagai berikut:
    ----------------------------------------------------
    #{withdrawal_detail(withdrawal)}
    ----------------------------------------------------

    Silahkan klik link berikut untuk melanjutkan proses penarikan dana:
    #{base_url}/admin/withdrawals/?action=confirm&token=#{token}

    --
    Tim Snappy
    """

    %{
      user: %{email: user.email},
      subject: "Konfirmasi Penarikan Dana",
      text: text,
      html: nil
    }
    |> App.Mailer.cast()
    |> App.Mailer.process_sync()
  end

  defp send_confirmed_email(withdrawal) do
    withdrawal = App.Repo.preload(withdrawal, :user)
    user = withdrawal.user

    text = """
    Halo #{user.email},

    Anda MENGKONFIRMASI penarikan dana sebagai berikut:
    ----------------------------------------------------
    #{withdrawal_detail(withdrawal)}
    ----------------------------------------------------

    Dana segera ditransfer ke rekening Anda di hari kerja berikutnya (maksimal dalam 3 hari kerja).

    *** PENTING ***
    Apabila dalam 3 hari kerja dana belum juga masuk ke rekening Anda, silahkan hubungi kami dengan membalas email ini.

    --
    Tim Snappy
    """

    %{
      user: %{email: user.email},
      subject: "Penarikan Dana Segera Diproses",
      text: text,
      html: nil
    }
    |> App.Mailer.cast()
    |> App.Mailer.process_sync()
  end

  defp send_cancelation_email(withdrawal) do
    withdrawal = App.Repo.preload(withdrawal, :user)
    user = withdrawal.user
    base_url = AppWeb.Utils.base_url()

    text = """
    Halo #{user.email},

    Anda telah MEMBATALKAN penarikan dana berikut:
    ----------------------------------------------------
    #{withdrawal_detail(withdrawal)}
    ----------------------------------------------------

    Berikut link untuk melihat daftar penarikan dana anda:
    #{base_url}/admin/withdrawals

    --
    Tim Snappy
    """

    %{
      user: %{email: user.email},
      subject: "Penarikan Dana Dibatalkan",
      text: text,
      html: nil
    }
    |> App.Mailer.cast()
    |> App.Mailer.process_sync()
  end
end
