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
      |> Enum.into(%{

      })
      |> App.Contents.create_content()

    content
  end
end
