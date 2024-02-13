defmodule AppWeb.PowAuthErrorHandler do
  use AppWeb, :controller
  alias Plug.Conn

  @spec call(Conn.t(), atom()) :: Conn.t()
  def call(conn, :not_authenticated) do
    conn
    |> redirect(to: ~p"/session/new")
  end

  @spec call(Conn.t(), atom()) :: Conn.t()
  def call(conn, :already_authenticated) do
    conn
    |> redirect(to: ~p"/")
  end
end
