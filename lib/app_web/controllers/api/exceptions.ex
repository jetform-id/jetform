defmodule AppWeb.Api.UnauthorizedRequestError do
  defexception plug_status: 401, message: "Unauthorized Request"
end

defmodule AppWeb.Api.BadRequestError do
  defexception plug_status: 400, message: "Bad Request"
end

defimpl Plug.Exception, for: Flop.InvalidParamsError do
  def status(_), do: 400
  def actions(_), do: []
end
