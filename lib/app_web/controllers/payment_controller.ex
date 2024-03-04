defmodule AppWeb.PaymentController do
  use AppWeb, :controller
  require Logger

  alias App.PaymentGateway.Midtrans
  alias App.Orders

  def midtrans_redirect(conn, %{"order_id" => payment_id} = params) do
    params =
      params
      |> Map.drop(["order_id"])
      |> Map.put("payment_id", payment_id)

    payment = Orders.get_payment!(payment_id)
    redirect(conn, to: ~p"/invoice/#{payment.order_id}?#{params}")
  end

  def midtrans_notification(conn, params) do
    with {:ok, status} <- Midtrans.verify_payload(params),
         {:ok, _payment} <- handle_status(status) do
      send_resp(conn, 200, "ok")
    else
      {:error, :invalid_payload} ->
        send_resp(conn, 400, "invalid payload")

      {:error, :payment_not_found} ->
        send_resp(conn, 404, "payment not found")

      err ->
        Logger.error("#{__MODULE__}.midtrans_notification/2 error: #{inspect(err)}")
        send_resp(conn, 500, "unknown error")
    end
  end

  defp handle_status(%{"order_id" => "payment_notif_test_" <> _}), do: {:ok, "test"}

  defp handle_status(%{"order_id" => payment_id} = status) do
    case Orders.get_payment(payment_id) do
      nil -> {:error, :payment_not_found}
      payment -> Orders.update_payment(payment, status)
    end
  end
end
