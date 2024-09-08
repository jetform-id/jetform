defmodule AppWeb.LiveAuth do
  @moduledoc """
  Based on:
  https://github.com/pow-auth/pow/issues/706
  """
  use AppWeb, :verified_routes
  import Phoenix.Component
  import Phoenix.LiveView
  alias AppWeb.Utils

  def on_mount(:admin, _params, session, socket) do
    socket =
      socket
      |> assign(:admin_menus, Utils.admin_menus())
      |> assign_new(:current_user, fn -> user_from_session(session) end)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      socket =
        socket
        # |> put_flash(
        #   :error,
        #   "Sesi anda telah berakhir, silahkan login kembali untuk melanjutkan."
        # )
        |> redirect(to: ~p"/signin")

      {:halt, socket}
    end
  end

  def on_mount(:default, _params, session, socket) do
    socket =
      socket
      |> assign_new(:current_user, fn -> user_from_session(session) end)

    {:cont, socket}
  end

  def user_from_session(session) do
    pow_config = [otp_app: :app]

    %Plug.Conn{
      private: %{
        plug_session_fetch: :done,
        plug_session: session,
        pow_config: [otp_app: :app]
      },
      owner: self(),
      remote_ip: {0, 0, 0, 0}
    }
    |> Map.put(:secret_key_base, AppWeb.Endpoint.config(:secret_key_base))
    |> Pow.Plug.Session.fetch(pow_config)
    |> then(fn {_conn, user} -> user end)
  end
end
