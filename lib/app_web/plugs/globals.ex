defmodule AppWeb.Plugs.Globals do
  import Plug.Conn
  alias AppWeb.Utils

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> assign(:marketing_site, Utils.marketing_site())
    |> assign(:admin_menus, Utils.admin_menus())
  end
end
