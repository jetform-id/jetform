defmodule Workers.InvalidateOrder do
  use Oban.Worker, queue: :default, max_attempts: 1
  require Logger
  alias App.Orders

  @doc """
  Create a new job to invalidate an order if it's still in pending state.
  """
  def create(%{status: :pending} = order) do
    %{id: order.id}
    |> __MODULE__.new(scheduled_at: order.valid_until)
    |> Oban.insert()
  end

  def create(_order) do
    {:ok, :noop}
  end

  @impl true
  def perform(%{args: %{"id" => id}}) do
    with %{status: :pending} = order <- Orders.get_order(id),
         {:ok, _order} <- Orders.update_order(order, %{status: :expired}) do
      :ok
    else
      # order not found
      nil ->
        :ok

      # order not in pending state
      %{status: _} ->
        :ok

      err ->
        Logger.warning("Failed updating order=#{id} during invalidation, reason: #{inspect(err)}")

        :ok
    end
  end
end
