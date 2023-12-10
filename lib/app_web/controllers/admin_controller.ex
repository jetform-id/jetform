defmodule AppWeb.AdminController do
  use AppWeb, :controller

  plug :unkonfirmed_email_flash

  def index(conn, _params) do
    conn = assign(conn, :show_footer, true)
    render(conn, :index)
  end

  defp unkonfirmed_email_flash(
         %{assigns: %{current_user: %{unconfirmed_email: unconfirmed_email}}} = conn,
         _params
       ) do
    case unconfirmed_email do
      nil ->
        conn

      email ->
        conn
        |> put_flash(
          :warning,
          "Click the link in the confirmation email to change your email to #{email}."
        )
    end
  end
end
