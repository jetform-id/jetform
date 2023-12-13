defmodule AppWeb.DashboardLive.Index do
  use AppWeb, :live_view

  @impl true
  def mount(
        _params,
        _session,
        %{assigns: %{current_user: %{unconfirmed_email: unconfirmed_email}}} = socket
      ) do
    socket =
      case unconfirmed_email do
        nil ->
          socket

        email ->
          socket
          |> put_flash(
            :warning,
            "Click the link in the confirmation email to change your email to #{email}."
          )
      end

    {:ok, assign(socket, :page_title, "Dashboard")}
  end
end
