defmodule AppWeb.PowAuthRoutes do
  use Pow.Phoenix.Routes
  use AppWeb, :verified_routes

  @impl true
  def registration_path(_conn, :new), do: "/signup"

  @impl true
  def registration_path(_conn, :create), do: "/signup"

  @impl true
  def registration_path(_conn, :edit), do: "/account"

  @impl true
  def session_path(_conn, :new, _params), do: "/signin"

  @impl true
  def session_path(_conn, :create, _params), do: "/signin"

  @impl true
  def after_sign_in_path(_conn), do: ~p"/"

  @impl true
  def after_registration_path(_conn), do: ~p"/"

  @impl true
  def after_user_updated_path(_conn), do: ~p"/account"

  @doc """
  Overriding the default URL for email confirmation and password reset to make sure it's pointing to the correct URL
  when subdomain mode is enabled.
  """
  @impl true
  def url_for(
        _conn,
        PowEmailConfirmation.Phoenix.ConfirmationController,
        :show,
        [token],
        _params
      ),
      do: "#{AppWeb.Utils.dashboard_url()}/confirm-email/#{token}"

  def url_for(
        _conn,
        PowResetPassword.Phoenix.ResetPasswordController,
        :edit,
        [token],
        _params
      ),
      do: "#{AppWeb.Utils.dashboard_url()}/reset-password/#{token}"

  def url_for(conn, plug, verb, vars, params),
    do: Pow.Phoenix.Routes.url_for(conn, plug, verb, vars, params)
end
