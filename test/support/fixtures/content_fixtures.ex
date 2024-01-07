defmodule App.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Content` context.
  """

  @doc """
  Generate a access.
  """
  def access_fixture(attrs \\ %{}) do
    {:ok, access} =
      attrs
      |> Enum.into(%{
        valid_until: ~U[2024-01-05 05:58:00Z]
      })
      |> App.Content.create_access()

    access
  end
end
