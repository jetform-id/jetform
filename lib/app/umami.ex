defmodule App.Umami do
  defmodule Params do
    @enforce_keys [:url, :startAt, :endAt, :unit]
    defstruct [:url, :startAt, :endAt, :unit, :type]

    def new(url) do
      now = Timex.now()
      start_at = Timex.shift(now, days: -7) |> Timex.to_unix()
      end_at = Timex.to_unix(now)

      %__MODULE__{
        url: url,
        startAt: start_at * 1000,
        endAt: end_at * 1000,
        unit: :day
      }
    end
  end

  @base_url "https://api.umami.is"
  def website_id, do: Application.get_env(:app, :umami)[:website_id]

  def stats(%Params{} = params) do
    get("stats", website_id(), params)
  end

  def pageviews(%Params{} = params) do
    get("pageviews", website_id(), params)
  end

  def metrics(%Params{} = params) do
    get("metrics", website_id(), params)
  end

  def get(op, website_id, %Params{} = params) do
    query = Map.from_struct(params) |> URI.encode_query()

    get_http_client()
    |> Tesla.get("/v1/websites/#{website_id}/#{op}?#{query}")
    |> handle_response()
  end

  defp get_http_client() do
    headers = [
      {"accept", "application/json"},
      {"x-umami-api-key", Application.fetch_env!(:app, :umami)[:api_key]}
    ]

    middlewares = [
      {Tesla.Middleware.BaseUrl, @base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Headers, headers}
    ]

    Tesla.client(middlewares)
  end

  defp handle_response({:ok, %Tesla.Env{status: 200, body: body}}) do
    {:ok, body}
  end

  defp handle_response({:ok, %Tesla.Env{status: _, body: body}}) do
    {:error, body}
  end

  defp handle_response(error), do: error
end
