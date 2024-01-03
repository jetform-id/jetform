defmodule App.Workers.InvalidateOrder do
  use Oban.Worker, queue: :default, max_attempts: 1
  require Logger
  alias App.Orders

  @impl true
  def perform(%{args: %{"order_id" => order_id}}) do
    with %{status: :pending} = order <- Orders.get_order(order_id),
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
        Logger.warning(
          "Failed updating order=#{order_id} during invalidation, reason: #{inspect(err)}"
        )

        :ok
    end
  end

  def create(order) do
    %{order_id: order.id}
    |> __MODULE__.new(scheduled_at: order.valid_until)
    |> Oban.insert()
  end
end
