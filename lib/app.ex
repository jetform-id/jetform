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

  def gen_qr_code(data, options \\ []) when is_binary(data) do
    b64str = data |> EQRCode.encode() |> EQRCode.png(options) |> Base.encode64()
    "data:image/png;base64," <> b64str
  end
end
