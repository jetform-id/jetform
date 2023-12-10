defmodule AppWeb.Plug.AdminMenus do
  import Plug.Conn

  use Phoenix.VerifiedRoutes,
    endpoint: AppWeb.Endpoint,
    router: AppWeb.Router,
    statics: AppWeb.static_paths()

  def init(opts), do: opts

  def call(conn, _opts) do
    menus = [
      %{title: "Dashboard", path: ~p"/", icon: "hero-chart-pie-solid"},
      %{title: "Products", path: ~p"/products", icon: "hero-squares-2x2-solid"},
      %{
        title: "Customers",
        path: ~p"/",
        icon: "hero-users-solid"
      },
      %{
        title: "Transactions",
        path: ~p"/",
        icon: "hero-receipt-percent-solid"
      },
      %{
        title: "Settings",
        icon: "hero-cog-6-tooth-solid",
        children: [
          %{title: "Account", path: ~p"/account", icon: nil},
          %{title: "Payouts", path: ~p"/payouts/bank-account", icon: nil}
        ]
      }
    ]

    assign(conn, :admin_menus, menus)
  end
end
