defmodule Workers.Withdrawal do
  use Oban.Worker, queue: :default, max_attempts: 3
  require Logger
  alias App.Users
  alias App.Credits

  def notify(withdrawal) do
    action =
      case withdrawal.status do
        :pending -> "withdrawal_confirmation"
        :submitted -> "withdrawal_confirmed"
        :cancelled -> "withdrawal_cancellation"
        :rejected -> "withdrawal_rejected"
        :success -> "withdrawal_success"
        _ -> "noop"
      end

    %{action: action, id: withdrawal.id}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  @impl true
  def perform(%{args: %{"action" => action, "id" => id}}) do
    case Credits.get_withdrawal(id) do
      nil ->
        Logger.warning("#{__MODULE__} warning: withdrawal=#{id} not found")

        :ok

      withdrawal ->
        case action do
          "withdrawal_confirmation" ->
            send_confirmation_email(withdrawal)

          "withdrawal_confirmed" ->
            send_confirmed_email(withdrawal)

          "withdrawal_cancellation" ->
            send_cancellation_email(withdrawal)

          "withdrawal_rejected" ->
            send_rejected_email(withdrawal)

          "withdrawal_success" ->
            send_success_email(withdrawal)

          _ ->
            :ok
        end
    end
  end

  @impl true
  def perform(_job) do
    :ok
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
    Akun Bank penerima: #{App.Users.bank_name(withdrawal.recipient_bank_name)} / #{withdrawal.recipient_bank_acc_name} / #{withdrawal.recipient_bank_acc_number}
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
    #{base_url}/admin/withdrawals/confirm/#{token}

    *** PENTING ***
    Kami tidak bertanggung jawab atas kesalahan transfer dana yang disebabkan oleh kesalahan nomor rekening, nama rekening, atau nama bank penerima.
    Oleh karena itu mohon pastikan data di atas sudah benar dan segera batalkan penarikan dana apabila ada kesalahan.

    --
    Tim JetForm
    """

    %{
      user: %{email: user.email},
      subject: "Konfirmasi Penarikan Dana",
      text: text,
      html: nil
    }
    |> App.Mailer.cast()
    |> App.Mailer.deliver()
  end

  defp send_confirmed_email(withdrawal) do
    admin_email = Application.fetch_env!(:app, :admin_email)
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
    - Apabila dalam 3 hari kerja dana belum juga masuk ke rekening Anda, silahkan hubungi kami dengan membalas email ini.

    --
    Tim JetForm
    """

    %{
      bcc: {"", admin_email},
      user: %{email: user.email},
      subject: "Penarikan Dana Segera Diproses",
      text: text,
      html: nil
    }
    |> App.Mailer.cast()
    |> App.Mailer.deliver()
  end

  defp send_cancellation_email(withdrawal) do
    withdrawal = App.Repo.preload(withdrawal, :user)
    user = withdrawal.user
    base_url = AppWeb.Utils.base_url()

    text = """
    Halo #{user.email},

    Penarikan dana berikut telah DIBATALKAN:
    ----------------------------------------------------
    #{withdrawal_detail(withdrawal)}
    ----------------------------------------------------

    Berikut link untuk melihat daftar penarikan dana anda:
    #{base_url}/admin/withdrawals

    --
    Tim JetForm
    """

    %{
      user: %{email: user.email},
      subject: "Penarikan Dana Dibatalkan",
      text: text,
      html: nil
    }
    |> App.Mailer.cast()
    |> App.Mailer.deliver()
  end

  defp send_rejected_email(withdrawal) do
    withdrawal = App.Repo.preload(withdrawal, :user)
    user = withdrawal.user

    text = """
    Halo #{user.email},

    Penarikan dana berikut telah DITOLAK:
    ----------------------------------------------------
    #{withdrawal_detail(withdrawal)}
    ----------------------------------------------------

    Alasan penolakan:
    #{withdrawal.admin_note}


    Apabila ada yang kurang jelas, silahkan hubungi kami dengan membalas email ini.

    --
    Tim JetForm
    """

    %{
      user: %{email: user.email},
      subject: "Penarikan Dana Ditolak",
      text: text,
      html: nil
    }
    |> App.Mailer.cast()
    |> App.Mailer.deliver()
  end

  defp send_success_email(withdrawal) do
    withdrawal = App.Repo.preload(withdrawal, :user)
    user = withdrawal.user

    text = """
    Halo #{user.email},

    Penarikan dana berikut telah SELESAI:
    ----------------------------------------------------
    #{withdrawal_detail(withdrawal)}
    ----------------------------------------------------

    Silahkan cek rekening Anda untuk memastikan dana telah masuk.


    *** PENTING ***
    Kami tidak bertanggung jawab atas kesalahan transfer dana yang disebabkan oleh kesalahan nomor rekening, nama rekening, atau nama bank penerima.

    --
    Tim JetForm
    """

    %{
      user: %{email: user.email},
      subject: "Penarikan Dana Berhasil",
      text: text,
      html: nil
    }
    |> App.Mailer.cast()
    |> App.Mailer.deliver()
  end
end
