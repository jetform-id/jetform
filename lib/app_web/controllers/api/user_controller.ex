defmodule AppWeb.API.UserController do
  use AppWeb, :controller
  alias App.Users

  @result_limit 20

  @moduledoc """
  Only returns confirmed users.
  """
  def index(%{assigns: %{current_user: user}} = conn, params) do
    # this is to support API clients that expect an array e.g Zapier
    as_array = params["as_array"] == "true"

    query = %{
      order_by: [:email_confirmed_at],
      order_directions: [:desc],
      page_size: @result_limit,
      page: Map.get(params, "page", "1"),
      filters: [%{field: :email_confirmed_at, op: :not_empty, value: true}]
    }

    {users, meta} = Users.list_users!(user, query)
    render(conn, :index, users: users, meta: meta, as_array: as_array)
  end
end
