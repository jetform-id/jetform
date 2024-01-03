defmodule App.Orders do
  @moduledoc """
  The Orders context.
  """
  require Logger
  import Ecto.Query, warn: false
  alias App.Repo
  alias Repo

  alias App.Orders.{Order, Payment}
  alias App.Contents

  # ------------- ORDERS -------------

  defdelegate time_before_expired(order), to: Order

  def generate_invoice_number() do
    month = Timex.now() |> Timex.format!("%y%m%d", :strftime)
    random = :crypto.strong_rand_bytes(2) |> :crypto.bytes_to_integer()
    "#{month}-#{random}"
  end

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders()
      [%Order{}, ...]

  """
  def list_orders do
    Repo.all(Order)
  end

  @doc """
  Returns the list of orders for a given user.
  """
  def list_orders!(user, params) do
    Order
    |> where(user_id: ^user.id)
    |> Flop.validate_and_run!(params)
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(123)
      %Order{}

      iex> get_order!(456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(id), do: Repo.get!(Order, id)
  def get_order(id), do: Repo.get(Order, id)

  @doc """
  Creates a order.

  ## Examples

      iex> create_order(%{field: value})
      {:ok, %Order{}}

      iex> create_order(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:order, Order.create_changeset(%Order{}, attrs))
    |> Ecto.Multi.run(:contents, fn repo, %{order: order} ->
      # get contents for order
      order = repo.preload(order, :product_variant)

      case order.product_variant do
        nil ->
          {:ok, Contents.list_contents_by_product(order.product)}

        variant ->
          {:ok, Contents.list_contents_by_variant(variant)}
      end
    end)
    |> Ecto.Multi.update(:order_contents, fn %{order: order, contents: contents} ->
      # put contents to order
      Repo.preload(order, :contents)
      |> Order.changeset(%{})
      |> Order.put_contents(contents)
    end)
    |> Ecto.Multi.run(:schedule_invalidation, fn _repo, %{order: order} ->
      # Schedule an Oban job to invalidate the order after it expires
      App.Workers.InvalidateOrder.create(order)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{order_contents: order}} ->
        {:ok, order}

      {:error, _op, _value, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Order{} = order, attrs) do
    order
    |> Order.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, order} ->
        # notify all subscribers (e.g. invoice page) that this order has been updated.
        Phoenix.PubSub.broadcast(
          App.PubSub,
          "order:#{order.id}",
          "order:updated"
        )

        {:ok, order}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deletes a order.

  ## Examples

      iex> delete_order(order)
      {:ok, %Order{}}

      iex> delete_order(order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Order{} = order) do
    Repo.delete(order)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(order)
      %Ecto.Changeset{data: %Order{}}

  """
  def change_order(%Order{} = order, attrs \\ %{}) do
    Order.changeset(order, attrs)
  end

  def valid_until_hours(value \\ 1) do
    DateTime.utc_now() |> DateTime.add(value, :hour)
  end

  # ------------- PAYMENTS -------------

  def get_payment(id), do: Repo.get(Payment, id)
  def get_payment!(id), do: Repo.get!(Payment, id)

  def get_empty_payment(order) do
    from(
      p in Payment,
      where: p.order_id == ^order.id,
      where: is_nil(p.trx_status)
    )
    |> Repo.one()
  end

  def fetch_pending_payments(order) do
    from(
      p in Payment,
      where: p.order_id == ^order.id,
      where: p.trx_status == "pending"
    )
    |> Repo.all()
  end

  def change_payment(%Payment{} = payment, attrs \\ %{}) do
    Payment.changeset(payment, attrs)
  end

  def change_payment_from_status(%Payment{} = payment, status) do
    Payment.changeset_from_status(payment, status)
  end

  @doc """
  Generate payload for Midtrans transactions API but only return the payload
  if the order is not about to expire (larger or equal to `minimum_expiry_mins`)

  To simplify payment time management, we strictly enforce te payment page expiry time as
  well as the transaction expiry time to be the same as Order `valid_until` time.
  """
  def midtrans_payload(order, payment, minimum_expiry_mins \\ 1) do
    # calculate the expiry time in minutes
    expiry_mins = Integer.floor_div(time_before_expired(order), 60)

    # create transaction in Midtrans
    item_details_name =
      case order.product_variant_name do
        nil -> order.product_name
        variant_name -> "#{order.product_name} - #{variant_name}"
      end

    payload = %{
      "transaction_details" => %{
        "order_id" => payment.id,
        "gross_amount" => order.total
      },
      "item_details" => [
        %{
          "id" => order.product_id,
          "price" => order.total,
          "quantity" => 1,
          "name" => item_details_name
        }
      ],
      "customer_details" => %{
        "first_name" => order.customer_name,
        "email" => order.customer_email
      },
      "expiry" => %{
        "start_time" => order.inserted_at |> Timex.format!("%F %T %z", :strftime),
        "unit" => "minutes",
        "duration" => expiry_mins
      },
      "page_expiry" => %{
        "duration" => expiry_mins,
        "unit" => "minutes"
      }
    }

    if expiry_mins <= minimum_expiry_mins do
      Logger.error(
        "#{__MODULE__}.midtrans_payload/2 error: Order #{order.id} is about to expire in #{expiry_mins} minutes"
      )

      {:error, :order_about_to_expire}
    else
      {:ok, payload}
    end
  end

  @doc """
  Create a payment for an order and generate Midtrans payment URL.
    0. delete all pending payments for this order before creating new one
    1. create payment record
    2. create midtrans transaction and get `redirect_url`
    3. update payment record with `redirect_url`
  """
  def create_payment(%Order{} = order) do
    fetch_pending_payments(order)
    |> Task.async_stream(&cancel_payment/1)
    |> Stream.run()

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:new_payment, Payment.create_changeset(%Payment{}, %{"order" => order}))
    |> Ecto.Multi.run(:redirect_url, fn _repo, %{new_payment: payment} ->
      with {:ok, payload} <- midtrans_payload(order, payment),
           {:ok, %{"redirect_url" => redirect_url}} <- App.Midtrans.create_transaction(payload) do
        {:ok, redirect_url}
      else
        {:error, :order_about_to_expire} ->
          {:error, :order_about_to_expire}

        {:error, err} ->
          Logger.error("#{__MODULE__}.create_payment/1 error: #{inspect(err)}")
          {:error, :midtrans_error}
      end
    end)
    |> Ecto.Multi.update(:updated_payment, fn %{new_payment: payment, redirect_url: redirect_url} ->
      Payment.changeset(payment, %{"redirect_url" => redirect_url})
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{updated_payment: payment, redirect_url: redirect_url}} ->
        {:ok, payment, redirect_url}

      {:error, _op, value, changeset} ->
        {:error, value, changeset}
    end
  end

  # custom guards
  defguard is_paid(transaction_status) when transaction_status in ["capture", "settlement"]
  defguard is_ok(status_code) when status_code == "200"
  defguard is_safe(fraud_status) when fraud_status in [nil, "accept"]

  def update_payment(
        %Payment{
          trx_status: old_status,
          status_code: status_code,
          fraud_status: fraud_status
        } = payment,
        _status
      )
      when is_paid(old_status) and is_ok(status_code) and is_safe(fraud_status) do
    # alread paid, do nothing
    {:ok, payment}
  end

  def update_payment(
        %{trx_status: old_status} = payment,
        %{
          "transaction_status" => new_status,
          "status_code" => status_code,
          "fraud_status" => fraud_status
        } = status
      )
      when not is_paid(old_status) and is_paid(new_status) and is_ok(status_code) and
             is_safe(fraud_status) do
    payment = Repo.preload(payment, :order)

    # payment successfull:
    # - update payment status
    # - update order status
    # - broadcast order:updated event
    # - create Oban job to deliver (create content access, send email to buyer) content
    Ecto.Multi.new()
    |> Ecto.Multi.update(:payment, change_payment_from_status(payment, status))
    |> Ecto.Multi.update(:order, change_order(payment.order, %{"status" => "paid"}))
    |> Repo.transaction()
    |> case do
      {:ok, %{payment: payment, order: order}} ->
        # notify all subscribers (e.g. invoice page) that this order has been updated.
        Phoenix.PubSub.broadcast(
          App.PubSub,
          "order:#{order.id}",
          "order:updated"
        )

        # create Oban job to deliver content
        # App.Workers.DeliverContent.create(order)

        {:ok, %{payment | order: order}}

      {:error, _op, value, changeset} ->
        {:error, value, changeset}
    end
  end

  def update_payment(%Payment{} = payment, %{} = status) do
    # other status, just update payment status
    change_payment_from_status(payment, status) |> Repo.update()
  end

  def refresh_payment(%Payment{} = payment) do
    with {:ok, status} <- App.Midtrans.get_transaction_status(payment.id),
         {:ok, payment} <- update_payment(payment, status) do
      {:ok, payment}
    else
      err -> err
    end
  end

  def cancel_payment(%Payment{} = payment) do
    App.Midtrans.cancel_transaction(payment.id)
  end
end
