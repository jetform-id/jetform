defmodule AppWeb.Subdomain.LiveContext do
  import Phoenix.Component
  alias App.Users

  def on_mount(:default, _params, session, socket) do
    tenant = Users.get_by_username!(session["subdomain"])
    {:cont, assign(socket, :tenant, tenant)}
  end
end
