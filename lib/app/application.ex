defmodule App.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AppWeb.Telemetry,
      App.Repo,
      {DNSCluster, query: Application.get_env(:app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: App.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: App.Finch},
      {Finch, name: App.FinchWithProxy, pools: finch_pool_options()},
      {Oban, Application.fetch_env!(:app, Oban)},
      {Redix,
       {Application.get_env(:app, :redis_url),
        [name: :redix, socket_opts: Application.get_env(:app, :redis_socket_opts)]}},
      {Cachex, name: :cache},
      # Start a worker by calling: App.Worker.start_link(arg)
      # {App.Worker, arg},
      # Start to serve requests, typically the last entry
      AppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: App.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AppWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp finch_pool_options do
    %{host: host, port: port, userinfo: userinfo} =
      Application.get_env(:app, :proxy_url) |> URI.parse()

    opts =
      if is_nil(userinfo),
        do: [proxy: {:http, host, port, []}],
        else: [
          proxy: {:http, host, port, []},
          proxy_headers: [
            {"Proxy-Authorization", "Basic #{Base.encode64(userinfo)}"}
          ]
        ]

    %{default: [conn_opts: opts]}
  end
end
