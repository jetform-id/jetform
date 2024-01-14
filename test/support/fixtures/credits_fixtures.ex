defmodule App.CreditsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Credits` context.
  """

  @doc """
  Generate a credit.
  """
  def credit_fixture(attrs \\ %{}) do
    {:ok, credit} =
      attrs
      |> Enum.into(%{
        withdrawable_at: ~U[2024-01-13 05:23:00Z]
      })
      |> App.Credits.create_credit()

    credit
  end
end
