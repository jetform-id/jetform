defmodule App.Mailer do
  use Pow.Phoenix.Mailer
  use Swoosh.Mailer, otp_app: :app

  import Swoosh.Email
  require Logger

  @impl true
  def cast(%{user: user, subject: subject, text: text, html: html} = params) do
    from_name = Application.fetch_env!(:app, :mailer_from_name)
    from_email = Application.fetch_env!(:app, :mailer_from_email)

    email =
      %Swoosh.Email{}
      |> to({Map.get(user, :name, ""), user.email})
      |> from({from_name, from_email})
      |> subject(subject)
      |> html_body(html)
      |> text_body(text)

    case params[:bcc] do
      nil -> email
      bcc -> bcc(email, bcc)
    end
  end

  @impl true
  def process(email) do
    # An asynchronous process should be used here to prevent enumeration
    # attacks. Synchronous e-mail delivery can reveal whether a user already
    # exists in the system or not.

    Task.start(fn ->
      email
      |> deliver()
      |> log_warnings()
    end)

    :ok
  end

  defp log_warnings({:error, reason}) do
    Logger.warning("Mailer backend failed with: #{inspect(reason)}")
  end

  defp log_warnings({:ok, response}), do: {:ok, response}
end
