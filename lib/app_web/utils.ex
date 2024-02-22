defmodule AppWeb.Utils do
  use AppWeb, :verified_routes

  def base_url do
    case System.get_env("PHX_HOST") do
      nil -> "http://localhost:4000"
      host -> "https://#{host}"
    end
  end

  def marketing_site, do: Application.fetch_env!(:app, :marketing_site)

  def admin_menus do
    [
      %{
        title: "Penjualan",
        path: ~p"/",
        icon: "hero-receipt-percent"
      },
      # %{title: "Dashboard", path: ~p"/", icon: "hero-chart-pie"},
      %{
        title: "Produk",
        path: ~p"/products",
        icon: "hero-squares-2x2"
      },
      # %{
      #   title: "Pembeli",
      #   path: ~p"/",
      #   icon: "hero-users"
      # },
      %{
        title: "Penarikan Dana",
        path: ~p"/withdrawals",
        icon: "hero-banknotes"
      }
      # %{
      #   title: "Settings",
      #   icon: "hero-cog-6-tooth",
      #   children: [
      #     %{title: "Account", path: ~p"/account", icon: nil}
      #   ]
      # }
    ]
  end
end
