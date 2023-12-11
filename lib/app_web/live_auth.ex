defmodule AppWeb.LiveAuth do
  @moduledoc """
  Based on:
  https://github.com/pow-auth/pow/issues/706
  """
  use AppWeb, :verified_routes
  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:admin, _params, session, socket) do
    socket = mount_current_user(socket, session)

    if socket.assigns.current_user do
      {:cont, assign(socket, :admin_menus, admin_menus())}
    else
      socket =
        socket
        |> put_flash(:error, "You must be logged in to access this page.")
        |> redirect(to: ~p"/session/new")

      {:halt, socket}
    end
  end

  defp mount_current_user(socket, session) do
    assign_new(socket, :current_user, fn ->
      pow_config = [otp_app: :app]

      {_conn, user} =
        %Plug.Conn{
          private: %{
            plug_session_fetch: :done,
            plug_session: session,
            pow_config: pow_config
          },
          owner: self(),
          remote_ip: {0, 0, 0, 0}
        }
        |> Map.put(:secret_key_base, AppWeb.Endpoint.config(:secret_key_base))
        |> Pow.Plug.Session.fetch(pow_config)

      user
    end)
  end

  defp admin_menus do
    [
      %{title: "Dashboard", path: ~p"/admin", icon: "hero-chart-pie-solid"},
      %{title: "Products", path: ~p"/admin/products", icon: "hero-squares-2x2-solid"},
      %{
        title: "Customers",
        path: ~p"/admin",
        icon: "hero-users-solid"
      },
      %{
        title: "Transactions",
        path: ~p"/admin",
        icon: "hero-receipt-percent-solid"
      },
      %{
        title: "Settings",
        icon: "hero-cog-6-tooth-solid",
        children: [
          %{title: "Account", path: ~p"/admin/account", icon: nil},
          %{title: "Payouts", path: ~p"/admin/payouts/bank-account", icon: nil}
        ]
      }
    ]
  end
end
