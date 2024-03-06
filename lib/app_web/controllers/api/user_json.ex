defmodule AppWeb.API.UserJSON do
  alias App.Users
  alias AppWeb.API.Utils

  def index(%{users: users, meta: _meta, as_array: true}) do
    Enum.map(users, &transform/1)
  end

  def index(%{users: users, meta: meta, as_array: _}) do
    %{data: Enum.map(users, &transform/1), meta: Utils.transform_flop_meta(meta)}
  end

  defp transform(%Users.User{} = user) do
    Map.take(user, [
      :id,
      :email,
      :role,
      :timezone,
      :plan,
      :plan_valid_until,
      :email_confirmed_at,
      :inserted_at,
      :updated_at
    ])
  end
end
