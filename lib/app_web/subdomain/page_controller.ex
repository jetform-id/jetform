defmodule AppWeb.Subdomain.PageController do
  use AppWeb, :controller

  def index(conn, _params) do
    redirect(conn, external: AppWeb.Utils.marketing_site())
  end
end
