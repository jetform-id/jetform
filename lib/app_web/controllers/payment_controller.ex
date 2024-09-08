defmodule AppWeb.PaymentController do
  use AppWeb, :controller
  require Logger

  alias App.PaymentGateway.{Midtrans, Ipaymu}
  alias App.Orders

  def ipaymu_redirect(conn, %{"payment_id" => payment_id} = params) do
    payment = Orders.get_payment!(payment_id) |> App.Repo.preload(:order)
    order = payment.order

    if order.status == :paid do
      redirect(conn, to: ~p"/invoices/#{order.id}/thanks")
    else
      redirect(conn, to: ~p"/invoices/#{order.id}?#{params}")
    end
  end

  @doc """
  Ipaymu's notification doesn't require signature, so we secure the endpoint by requiring
  our payment_id in the path e.g. /payment/ipaymu/:payment_id/notification

  - check payment existance by ID
  - get transaction status from Ipaymu
  - pass to downstream handler
  """
  def ipaymu_notification(
        conn,
        %{"payment_id" => payment_id, "trx_id" => trx_id, "signature" => signature} = payload
      ) do
    with {:ok, id} <- Phoenix.Token.verify(conn, "payment_id", signature),
         true <- payment_id == id,
         %{} = payment <- Orders.get_payment(payment_id),
         {:ok, _} <-
           Orders.create_payment_notification(Orders.change_payment_notification(conn, payment)),
         {:ok, result} <- Ipaymu.get_transaction(trx_id),
         attrs <- Orders.to_payment_attrs(result) |> Map.put("notification_payload", payload),
         {:ok, _payment} <- Orders.update_payment(payment, attrs) do
      send_resp(conn, 200, "ok")
    else
      err ->
        Logger.error("#{__MODULE__}.ipaymu_notification/2 error: #{inspect(err)}")
        send_resp(conn, 500, "error")
    end
  end

  def midtrans_redirect(conn, %{"order_id" => payment_id} = params) do
    payment = Orders.get_payment!(payment_id) |> App.Repo.preload(:order)
    order = payment.order

    if order.status == :paid do
      redirect(conn, to: ~p"/invoices/#{order.id}/thanks")
    else
      params =
        params
        |> Map.drop(["order_id"])
        |> Map.put("payment_id", payment_id)

      redirect(conn, to: ~p"/invoices/#{order.id}?#{params}")
    end
  end

  def midtrans_notification(conn, params) do
    with {:ok, status} <- Midtrans.verify_payload(params),
         {:ok, _payment} <- midtrans_handle_status(status) do
      send_resp(conn, 200, "ok")
    else
      {:error, :invalid_payload} ->
        send_resp(conn, 400, "invalid payload")

      err ->
        Logger.error("#{__MODULE__}.midtrans_notification/2 error: #{inspect(err)}")
        send_resp(conn, 500, "error")
    end
  end

  defp midtrans_handle_status(%{"order_id" => "payment_notif_test_" <> _}), do: {:ok, "test"}

  defp midtrans_handle_status(%{"order_id" => payment_id, "transaction_id" => trx_id}) do
    payment = Orders.get_payment!(payment_id)

    with {:ok, trx} <- Midtrans.get_transaction(trx_id),
         {:ok, payment} <- Orders.update_payment(payment, Map.from_struct(trx)) do
      {:ok, payment}
    else
      error -> error
    end
  end
end
