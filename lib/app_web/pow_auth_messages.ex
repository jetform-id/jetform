defmodule AppWeb.PowAuthMessages do
  use Pow.Phoenix.Messages

  use Pow.Extension.Phoenix.Messages,
    extensions: [PowResetPassword, PowEmailConfirmation]

  # overrides auth messages
  def invalid_credentials(_conn),
    do: "Email atau password yang Anda masukkan salah."

  def user_has_been_updated(_conn), do: "Akun berhasil diperbarui."

  def user_has_been_deleted(_conn),
    do: "Akun anda telah dihapus. Sayang sekali melihat Anda pergi!"

  def user_could_not_be_deleted(_conn), do: "Akun gagal dihapus. Silahkan coba lagi."

  # overrides email confirmation messages
  def pow_email_confirmation_email_has_been_confirmed(_conn),
    do: "Email telah dikonfirmasi."

  def pow_email_confirmation_email_confirmation_failed(_conn),
    do: "Email gagal dikonfirmasi. Silakan coba lagi."

  def pow_email_confirmation_invalid_token(_conn),
    do: "Link konfirmasi email tidak valid atau kadaluarsa. Silakan coba lagi."

  def pow_email_confirmation_email_confirmation_required(_conn),
    do:
      "Anda perlu mengkonfirmasi email sebelum bisa login. Link konfirmasi telah dikirimkan ke email Anda."

  def pow_email_confirmation_email_confirmation_required_for_update(_conn),
    do:
      "Anda perlu mengkonfirmasi email yang baru sebelum bisa digunakan. Link konfirmasi telah dikirimkan ke email Anda yang baru."

  # overrides reset password messages
  def pow_reset_password_maybe_email_has_been_sent(_conn),
    do: "Link reset password sudah dikirimkan, silahkan cek email Anda."

  def pow_reset_password_email_has_been_sent(conn),
    do: pow_reset_password_maybe_email_has_been_sent(conn)

  def pow_reset_password_user_not_found(_conn),
    do: "Akun dengan email yang anda masukkan tidak ditemukan. Silakan coba lagi."

  def pow_reset_password_invalid_token(_conn),
    do: "Link reset password tidak valid atau kadaluarsa."

  def pow_reset_password_password_has_been_reset(_conn), do: "Password berhasil diganti."
end
