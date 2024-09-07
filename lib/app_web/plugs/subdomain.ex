defmodule AppWeb.Plugs.Subdomain do
  import Plug.Conn

  def init(_opts) do
    %{
      router: AppWeb.Subdomain.Router,
      root_host: Application.get_env(:app, AppWeb.Endpoint)[:url][:host]
    }
  end

  def call(%{host: host} = conn, %{root_host: root_host, router: router} = _opts) do
    enabled = Application.get_env(:app, :enable_subdomains, false)
    dashboard_subdomain = Application.get_env(:app, :dashboard_subdomain, "app")

    if enabled do
      case extract_subdomain(host, root_host) do
        subdomain when byte_size(subdomain) > 0 ->
          # if accessing the dashboard subdomain, do nothing
          if subdomain == dashboard_subdomain do
            conn
          else
            conn
            |> assign(:subdomain, subdomain)
            |> put_session(:subdomain, subdomain)
            |> router.call(router.init({}))
            |> halt()
          end

        _ ->
          conn
      end
    else
      conn
    end
  end

  defp extract_subdomain(host, root_host) do
    String.replace(host, ~r/.?#{root_host}/, "")
  end
end
