defmodule AppWeb.UmamiController do
  use AppWeb, :controller

  def index(conn, params) do
    case App.Umami.send(params, conn.req_headers) do
      {:ok, _} -> resp(conn, 200, "ok")
      {:error, error} -> resp(conn, 500, error)
    end
  end
end
