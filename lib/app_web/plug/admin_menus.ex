defmodule AppWeb.Plug.AdminMenus do
  use AppWeb, :verified_routes
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    menus = [
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

    assign(conn, :admin_menus, menus)
  end
end
