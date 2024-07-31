defmodule App.ContentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Contents` context.
  """

  @doc """
  Generate a content.
  """
  def content_fixture(attrs \\ %{}) do
    {:ok, content} =
      attrs
      |> Enum.into(%{})
      |> App.Contents.create_content()

    content
  end

  @doc """
  Generate a access.
  """
  def access_fixture(attrs \\ %{}) do
    {:ok, access} =
      attrs
      |> Enum.into(%{
        valid_until: ~U[2024-01-05 05:59:00Z]
      })
      |> App.Contents.create_access()

    access
  end
end
