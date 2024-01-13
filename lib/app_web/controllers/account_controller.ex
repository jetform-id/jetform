defmodule AppWeb.AccountController do
  use AppWeb, :controller
  alias App.Plans

  def edit(conn, _params) do
    changeset = Pow.Plug.change_user(conn)
    plan = Plans.get(conn.assigns.current_user.plan)

    render(conn, :edit,
      page_title: "Edit Account",
      changeset: changeset,
      action: ~p"/admin/account",
      plan: plan
    )
  end

  def update(conn, %{"user" => user_params}) do
    case Pow.Plug.update_user(conn, user_params) do
      {:ok, _user, conn} ->
        conn
        |> put_flash(:info, "Your account has been updated.")
        |> redirect(to: ~p"/admin/account")

      {:error, changeset, conn} ->
        render(conn, :edit, changeset: changeset, action: ~p"/admin/account")
    end
  end
end
