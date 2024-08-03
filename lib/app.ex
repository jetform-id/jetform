defmodule App do
  @moduledoc """
  App keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @doc """
  Get active payment provider.
  """
  def payment_provider do
    Application.get_env(:app, :payment_provider)
  end
end
