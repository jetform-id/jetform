defmodule AppWeb.Utils do
  use AppWeb, :verified_routes

  def base_url(subdomain \\ nil) do
    url = Application.get_env(:app, AppWeb.Endpoint)[:url]
    scheme = Keyword.get(url, :scheme, "http")
    host = url[:host]
    port = Keyword.get(url, :port, 4000)

    port_str = if port in [80, 443], do: "", else: ":#{port}"

    if subdomain do
      "#{scheme}://#{subdomain}.#{host}#{port_str}"
    else
      "#{scheme}://#{host}#{port_str}"
    end
  end

  def dashboard_url do
    if Application.get_env(:app, :enable_subdomains) do
      Application.get_env(:app, :dashboard_subdomain) |> base_url()
    else
      base_url()
    end
  end

  def user_url(username) when is_binary(username) do
    if Application.get_env(:app, :enable_subdomains) do
      base_url(username)
    else
      base_url() <> "/" <> username
    end
  end

  def user_url(user) do
    user_url(user.username)
  end

  def product_url(product, options \\ []) do
    product = product |> App.Repo.preload(:user)
    user = product.user

    params = Keyword.get(options, :params, %{})
    preview = Keyword.get(options, :preview, false)

    query_params =
      cond do
        preview == true ->
          token = Phoenix.Token.sign(AppWeb.Endpoint, "preview_token", product.id)
          params = params |> Map.put("preview_token", token)
          "?" <> URI.encode_query(params)

        preview == false && not Enum.empty?(params) ->
          "?" <> URI.encode_query(params)

        true ->
          ""
      end

    if Application.get_env(:app, :enable_subdomains) do
      base_url(user.username) <> "/" <> product.slug <> query_params
    else
      user_url(user) <> "/" <> product.slug <> query_params
    end
  end

  def marketing_site, do: Application.fetch_env!(:app, :marketing_site)

  def admin_menus do
    [
      %{
        title: "Dashboard",
        path: ~p"/",
        icon: "hero-home"
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
