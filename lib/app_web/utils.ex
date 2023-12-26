defmodule AppWeb.Utils do
  use AppWeb, :verified_routes

  def base_url do
    url = Application.fetch_env!(:app, AppWeb.Endpoint)[:url]
    http = Application.fetch_env!(:app, AppWeb.Endpoint)[:http]
    host = Keyword.get(url, :host, "localhost")
    scheme = Keyword.get(url, :scheme, "http")
    port = Keyword.get(http, :port, 4000)

    case port do
      80 -> scheme <> "://" <> host
      443 -> scheme <> "://" <> host
      port -> scheme <> "://" <> host <> ":" <> Integer.to_string(port)
    end
  end

  def admin_menus do
    [
      %{
        title: "Penjualan",
        path: ~p"/admin",
        icon: "hero-receipt-percent-solid"
      },
      # %{title: "Dashboard", path: ~p"/admin", icon: "hero-chart-pie-solid"},
      %{
        title: "Produk",
        path: ~p"/admin/products",
        icon: "hero-squares-2x2-solid"
      },
      # %{
      #   title: "Pembeli",
      #   path: ~p"/admin",
      #   icon: "hero-users-solid"
      # },
      %{
        title: "Payouts",
        path: ~p"/admin/payouts/bank-account",
        icon: "hero-banknotes-solid"
      }
      # %{
      #   title: "Settings",
      #   icon: "hero-cog-6-tooth-solid",
      #   children: [
      #     %{title: "Account", path: ~p"/admin/account", icon: nil}
      #   ]
      # }
    ]
  end
end
