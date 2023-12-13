defmodule AppWeb.Plug.Globals do
  import Plug.Conn
  alias AppWeb.Utils

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> assign(:base_url, Utils.base_url())
    |> assign(:admin_menus, Utils.admin_menus())
  end
end
