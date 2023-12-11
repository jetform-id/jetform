defmodule AppWeb.PowAuthRoutes do
  use Pow.Phoenix.Routes
  use AppWeb, :verified_routes

  @impl true
  def after_sign_in_path(_params), do: ~p"/admin"

  @impl true
  def after_registration_path(_params), do: ~p"/admin"
end
