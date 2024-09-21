defmodule AppWeb.AccessController do
  use AppWeb, :controller
  alias App.{Repo, Orders, Contents}

  def index(conn, %{"id" => id}) do
    with %{} = access <- Contents.get_access(id),
         true <- Contents.access_is_valid?(access) do
      %{order: order} = access = Repo.preload(access, order: [:contents])

      conn =
        conn
        |> assign(:page_title, "Akses " <> Orders.product_fullname(order))
        |> assign(:body_class, "bg-slate-300")
        |> assign(:order, order)
        |> assign(:access, access)
        |> assign(:contents, order.contents)

      render(conn, :index)
    else
      _ ->
        raise Ecto.NoResultsError, queryable: App.Contents.Access
    end
  end
end
