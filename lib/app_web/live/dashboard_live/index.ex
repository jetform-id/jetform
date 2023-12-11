defmodule AppWeb.DashboardLive.Index do
  use AppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Dashboard")

    {:ok, socket}
  end
end
