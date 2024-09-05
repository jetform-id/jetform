defmodule App.Orders do
  @moduledoc """
  The Orders context.
  """
  import Ecto.Query, warn: false
  require Logger

  alias App.Repo
  alias App.Orders.{Order, Payment, PaymentNotification}
  alias App.Contents
  alias App.Credits
  alias App.PaymentGateway.GetTransactionResult

  # ------------- ORDERS -------------

  defdelegate time_before_expired(order), to: Order

  def generate_invoice_number() do
    month = Timex.now() |> Timex.format!("%y%m%d", :strftime)
    random = :crypto.strong_rand_bytes(2) |> :crypto.bytes_to_integer()
    "#{month}-#{random}"
  end

  def product_fullname(%Order{} = order) do
    case order.product_variant_name do
      nil -> order.product_name
      variant_name -> "#{order.product_name} (#{variant_name})"
    end
  end

  def stats_by_user_and_time(user, start_at \\ nil) do
    start_at = start_at || user.email_confirmed_at

    from(o in Order,
      select: {
        fragment("sum(case when status = 'free' then 1 else 0 end) as free_count"),
        fragment("sum(case when status = 'paid' then 1 else 0 end) as paid_count"),
        fragment("sum(case when status = 'expired' then 1 else 0 end) as expired_count"),
        fragment("sum(case when status = 'paid' then total else 0 end) as gross_revenue"),
        fragment("sum(case when status = 'paid' then service_fee else 0 end) as service_fee"),
        fragment("sum(case when status = 'paid' then gateway_fee else 0 end) as gateway_fee")
      },
      where: o.user_id == ^user.id,
      where: o.inserted_at >= ^start_at
    )
    |> Repo.one()
    |> then(fn {free_count, paid_count, expired_count, gross_revenue, service_fee, gateway_fee} ->
      %{
        free_count: free_count || 0,
        paid_count: paid_count || 0,
        expired_count: expired_count || 0,
        gross_revenue: gross_revenue || 0,
        service_fee: service_fee || 0,
        gateway_fee: gateway_fee || 0
      }
    end)
  end

  def stats_by_product_and_time(product, start_at \\ nil) do
    start_at = start_at || product.inserted_at

    from(o in Order,
      select: {
        fragment("sum(case when status = 'free' then 1 else 0 end) as free_count"),
        fragment("sum(case when status = 'paid' then 1 else 0 end) as paid_count"),
        fragment("sum(case when status = 'expired' then 1 else 0 end) as expired_count"),
        fragment("sum(case when status = 'paid' then total else 0 end) as gross_revenue"),
        fragment("sum(case when status = 'paid' then service_fee else 0 end) as service_fee"),
        fragment("sum(case when status = 'paid' then gateway_fee else 0 end) as gateway_fee")
      },
      where: o.product_id == ^product.id,
      where: o.inserted_at >= ^start_at
    )
    |> Repo.one()
    |> then(fn {free_count, paid_count, expired_count, gross_revenue, service_fee, gateway_fee} ->
      %{
        free_count: free_count || 0,
        paid_count: paid_count || 0,
        expired_count: expired_count || 0,
        gross_revenue: gross_revenue || 0,
        service_fee: service_fee || 0,
        gateway_fee: gateway_fee || 0
      }
    end)
  end

  def daily_counts_by_user(user, start_at \\ nil) do
    start_at = start_at || user.email_confirmed_at

    from(o in Order,
      select: {
        fragment("date_trunc('day', inserted_at) as date"),
        fragment("sum(case when status = 'free' then 1 else 0 end) as free_count"),
        fragment("sum(case when status = 'paid' then 1 else 0 end) as paid_count")
      },
      where: o.user_id == ^user.id,
      where: o.inserted_at >= ^start_at,
      group_by: fragment("date")
    )
    |> Repo.all()
  end

  def daily_counts_by_product(product, start_at \\ nil) do
    start_at = start_at || product.inserted_at

    from(o in Order,
      select: {
        fragment("date_trunc('day', inserted_at) as date"),
        fragment("sum(case when status = 'free' then 1 else 0 end) as free_count"),
        fragment("sum(case when status = 'paid' then 1 else 0 end) as paid_count")
      },
      where: o.product_id == ^product.id,
      where: o.inserted_at >= ^start_at,
      group_by: fragment("date")
    )
    |> Repo.all()
  end

  def top_products(user, start_at \\ nil) do
    start_at = start_at || user.email_confirmed_at

    from(o in Order,
      select: [
        o.product_id,
        o.product_variant_id,
        fragment("MIN(?)", o.product_name),
        fragment("MIN(?)", o.product_variant_name),
        count(o.id)
      ],
      where: o.user_id == ^user.id,
      where: o.inserted_at >= ^start_at,
      group_by: [o.product_id, o.product_variant_id],
      order_by: [desc: count(o.id)],
      limit: 5
    )
    |> Repo.all()
    |> Enum.map(fn [product_id, product_variant_id, product_name, product_variant_name, count] ->
      %{
        product_id: product_id,
        product_variant_id: product_variant_id,
        product_name: product_name,
        product_variant_name: product_variant_name,
        count: count
      }
    end)
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
  def list_orders!(user, query) do
    from(
      o in Order,
      where: not is_nil(o.product_id)
    )
    |> list_orders_by_user_scope(user)
    |> Flop.validate_and_run!(query)
  end

  def list_orders_by_user_scope(q, %{role: :admin}), do: q

  def list_orders_by_user_scope(q, user) do
    where(q, [o], o.user_id == ^user.id)
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

  def draft_order(attrs \\ %{}) do
    Order.create_changeset(%Order{}, attrs) |> Repo.insert()
  end

  def commit_order(%Order{} = order) do
    Ecto.Multi.new()
    |> Ecto.Multi.put(:order, order)
    |> multi_update__add_contents()
    |> multi_run__create_access()
    |> multi_run__background_jobs()
    |> Repo.transaction(timeout: Application.fetch_env!(:app, :db_transaction_timeout))
    |> case do
      {:ok, %{order: order}} ->
        {:ok, order}

      {:error, op, %Ecto.Changeset{} = changeset, _changes_so_far} ->
        Logger.error("commit_order/1 error: op=#{inspect(op)}, changeset=#{inspect(changeset)}")
        {:error, changeset}

      err ->
        Logger.error("commit_order/1 error=#{inspect(err)}")
        err
    end
  end

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
    |> multi_update__add_contents()
    |> multi_run__create_access()
    |> multi_run__background_jobs()
    |> Repo.transaction(timeout: Application.fetch_env!(:app, :db_transaction_timeout))
    |> case do
      {:ok, %{order: order}} ->
        {:ok, order}

      {:error, op, %Ecto.Changeset{} = changeset, _changes_so_far} ->
        Logger.error("create_order/1 error: op=#{inspect(op)}, changeset=#{inspect(changeset)}")
        {:error, changeset}

      err ->
        Logger.error("create_order/1 error=#{inspect(err)}")
        err
    end
  end

  def multi_update__add_contents(%Ecto.Multi{} = multi) do
    Ecto.Multi.update(multi, :order_with_contents, fn %{order: order} ->
      # get contents for order
      order = Repo.preload(order, [:product_variant, :contents])

      contents =
        case order.product_variant do
          nil -> Contents.list_contents_by_product(order.product)
          variant -> Contents.list_contents_by_variant(variant)
        end

      # put contents to order
      order
      |> Order.changeset(%{})
      |> Order.put_contents(contents)
    end)
  end

  def multi_run__create_access(%Ecto.Multi{} = multi) do
    # If order is free, create content access for buyer
    Ecto.Multi.run(multi, :access, fn
      _repo, %{order: %{status: :free} = order} ->
        Contents.create_changeset_for_order(order) |> Contents.create_access()

      _repo, _ ->
        {:ok, nil}
    end)
  end

  def multi_run__background_jobs(%Ecto.Multi{} = multi) do
    Ecto.Multi.run(multi, :bg_jobs, fn _repo, %{order: order, access: access} ->
      # - (if: pending) schedule a job to invalidate the order after it expires
      # - (always) notify buyer about the order
      # - (if: paid) notify buyer about their access to the product
      with {:ok, _} <- Workers.InvalidateOrder.create(order),
           {:ok, _} <- Workers.NotifyNewOrder.create(order),
           {:ok, _} <- Workers.NotifyNewAccess.create(access) do
        {:ok, true}
      else
        err -> err
      end
    end)
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

  def total_fee(%Order{} = order) do
    order.service_fee + order.gateway_fee
  end

  def net_amount(%Order{} = order) do
    order.total - total_fee(order)
  end

  # ------------- PAYMENTS -------------

  def list_payment_channels(options \\ []) do
    only = Keyword.get(options, :only, ["qris", "va"])
    provider_id = App.payment_provider().id()
    cache_key = "payment_provider:#{provider_id}:payment_channels"

    cached =
      Cachex.fetch(:cache, cache_key, fn _key ->
        channels = App.payment_provider().list_channels()

        if Enum.empty?(channels) do
          {:ignore, []}
        else
          {:commit, channels, ttl: :timer.hours(1)}
        end
      end)

    case cached do
      {:ok, channels} -> channels
      {:ignore, _} -> []
      {:commit, channels, _} -> channels
    end
    |> App.payment_provider().filter_channels(only: only)
  end

  def flatten_payment_channels(channels) do
    Enum.flat_map(channels, fn chan ->
      method = chan.code

      Enum.map(chan.channels, fn channel ->
        channel
        |> Map.put(:key, "#{method}:#{channel.code}")
        |> Map.put(:method, method)
      end)
    end)
  end

  def find_payment_channel(key, options \\ []) do
    list_payment_channels(options)
    |> flatten_payment_channels()
    |> Enum.find(fn channel -> channel.key == key end)
  end

  def get_payment(id), do: Repo.get(Payment, id)
  def get_payment!(id), do: Repo.get!(Payment, id)

  def get_pending_payment(order) do
    from(
      p in Payment,
      where: p.order_id == ^order.id,
      where: p.trx_status == "pending"
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

  @doc """
  Create a payment for an order and generate payment URL.
    1. create payment record
    2. create transaction and get `redirect_url`
    3. update payment record with `redirect_url`
  """
  def create_payment(order, options \\ [])

  def create_payment(%Order{status: :free}, _options), do: {:ok, nil}

  def create_payment(%Order{} = order, options) do
    payment_channel = Keyword.get(options, :payment_channel)

    Ecto.Multi.new()
    |> create_payment_multi(order, payment_channel)
    |> Repo.transaction(timeout: Application.fetch_env!(:app, :db_transaction_timeout))
    |> case do
      {:ok, %{update_payment: payment}} ->
        {:ok, payment}

      {:error, :create_transaction, reason, _changes_so_far} ->
        Logger.error("create_payment/1 error: op=create_transaction, reason=#{inspect(reason)}")
        {:error, :provider_error}

      {:error, op, %Ecto.Changeset{} = changeset, _changes_so_far} ->
        Logger.error("create_payment/1 error: op=#{inspect(op)}, changeset=#{inspect(changeset)}")
        {:error, changeset}

      err ->
        Logger.error("create_payment/1 error=#{inspect(err)}")
        err
    end
  end

  def create_payment_multi(multi, %Order{} = order, payment_channel) do
    multi
    |> multi_insert__create_payment(:create_payment, fn ->
      %{order: order, payment_channel: payment_channel}
    end)
    |> multi_run__create_transaction(:create_transaction, fn _, data ->
      %{payment: data.create_payment, order: order, payment_channel: payment_channel}
    end)
    |> multi_update__payment_with_transaction(:update_payment, fn data ->
      %{payment: data.create_payment, transaction: data.create_transaction}
    end)
  end

  def multi_insert__create_payment(%Ecto.Multi{} = multi, name, data_fn) do
    %{order: order, payment_channel: payment_channel} = data_fn.()

    Ecto.Multi.insert(
      multi,
      name,
      Payment.create_changeset(%Payment{}, %{
        "order" => order,
        "provider" => App.payment_provider().id(),
        "type" => payment_channel,
        "trx_status" => "pending"
      })
    )
  end

  def multi_run__create_transaction(%Ecto.Multi{} = multi, name, data_fn) do
    Ecto.Multi.run(multi, name, fn repo, data ->
      %{payment: payment, order: order, payment_channel: payment_channel} = data_fn.(repo, data)

      case payment_channel do
        nil ->
          App.payment_provider().create_redirect_transaction_payload(order, payment,
            payment_channel: payment_channel
          )
          |> App.payment_provider().create_redirect_transaction()

        _ ->
          App.payment_provider().create_direct_transaction_payload(order, payment,
            payment_channel: payment_channel
          )
          |> App.payment_provider().create_direct_transaction()
      end
    end)
  end

  def multi_update__payment_with_transaction(%Ecto.Multi{} = multi, name, data_fun) do
    Ecto.Multi.update(multi, name, fn data ->
      %{payment: payment, transaction: result} = data_fun.(data)

      Payment.changeset(payment, %{
        "create_transaction_response" => result.data,
        "trx_id" => result.id,
        "redirect_url" => result.redirect_url
      })
    end)
  end

  defguard is_paid(transaction_status) when transaction_status == "paid"
  defguard is_cancelled(transaction_status) when transaction_status == "cancel"

  def update_payment(%Payment{trx_status: old_status} = payment, _attrs)
      when is_paid(old_status) do
    # alread paid, do nothing
    {:ok, payment}
  end

  def update_payment(%Payment{trx_status: old_status} = payment, _attrs)
      when is_cancelled(old_status) do
    # alread cancelled, do nothing
    {:ok, payment}
  end

  def update_payment(
        %{trx_status: old_status} = payment,
        %{"trx_status" => new_status} = attrs
      )
      when not is_paid(old_status) and is_paid(new_status) do
    payment = Repo.preload(payment, :order)
    # payment successfull:
    # - update payment status
    # - update order status
    # - create credit for seller
    # - create content access for buyer
    # - broadcast order:updated event
    # - create Oban job to deliver (create content access, send email to buyer) content
    Ecto.Multi.new()
    |> Ecto.Multi.update(:payment, Payment.changeset(payment, attrs))
    |> Ecto.Multi.update(
      :order,
      fn %{payment: p} ->
        change_order(p.order, %{
          "status" => "paid",
          # payment's gross amount is in float :-(
          "total" => trunc(p.gross_amount),
          "payment_type" => p.type,
          "gateway_fee" => p.fee,
          "paid_at" => Timex.now()
        })
      end
    )
    |> Ecto.Multi.insert(:credit, fn %{order: order} ->
      Credits.create_changeset_for_order(order)
    end)
    |> Ecto.Multi.insert(:access, fn %{order: order} ->
      Contents.create_changeset_for_order(order)
    end)
    |> Ecto.Multi.run(:workers, fn _repo, %{order: order, access: access} ->
      # - notify product owner and buyer about paid order
      # - create a job to deliver (create content access, send email to buyer) content
      with {:ok, _} <- Workers.NotifyPaidOrder.create(order),
           {:ok, _} <- Workers.NotifyNewAccess.create(access) do
        {:ok, true}
      else
        err -> err
      end
    end)
    |> Repo.transaction(timeout: Application.fetch_env!(:app, :db_transaction_timeout))
    |> case do
      {:ok, %{payment: payment, order: order}} ->
        # notify all subscribers (e.g. invoice page) that this order has been updated.
        Phoenix.PubSub.broadcast(
          App.PubSub,
          "payment:#{payment.id}",
          "payment:updated"
        )

        Phoenix.PubSub.broadcast(
          App.PubSub,
          "order:#{order.id}",
          "order:updated"
        )

        {:ok, %{payment | order: order}}

      {:error, op, %Ecto.Changeset{} = changeset, _changes_so_far} ->
        Logger.error("update_payment/2 error: op=#{inspect(op)}, changeset=#{inspect(changeset)}")
        {:error, changeset}

      err ->
        Logger.error("update_payment/2 error=#{inspect(err)}")
        err
    end
  end

  def update_payment(%Payment{} = payment, attrs) do
    # other status, just update payment status
    case Payment.changeset(payment, attrs) |> Repo.update() do
      {:ok, payment} ->
        Phoenix.PubSub.broadcast(
          App.PubSub,
          "payment:#{payment.id}",
          "payment:updated"
        )

        {:ok, payment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def refresh_payment(%Payment{} = payment) do
    with {:ok, result} <- App.payment_provider().get_transaction(payment.id),
         {:ok, payment} <- update_payment(payment, to_payment_attrs(result)) do
      {:ok, payment}
    else
      err -> err
    end
  end

  def switch_payment(%Payment{} = current_payment, to_channel) do
    current_payment = current_payment |> App.Repo.preload(:order)
    order = current_payment.order

    # cancel the old payment
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :cancel_payment,
      change_payment(current_payment, %{
        "trx_status" => "cancel",
        "cancellation_reason" => "switch to #{to_channel}"
      })
    )
    # create a new payment
    |> create_payment_multi(order, to_channel)
    |> Repo.transaction(timeout: Application.fetch_env!(:app, :db_transaction_timeout))
    |> case do
      {:ok, %{update_payment: payment}} ->
        {:ok, payment}

      {:error, :create_transaction, reason, _changes_so_far} ->
        Logger.error("switch_payment/2 error: op=create_transaction, reason=#{inspect(reason)}")
        {:error, :provider_error}

      {:error, op, %Ecto.Changeset{} = changeset, _changes_so_far} ->
        Logger.error("switch_payment/2 error: op=#{inspect(op)}, changeset=#{inspect(changeset)}")
        {:error, changeset}

      err ->
        Logger.error("switch_payment/2 error=#{inspect(err)}")
        err
    end
  end

  def cancel_payment(%Payment{} = payment, options \\ []) do
    cancel_order = Keyword.get(options, :cancel_order, false)
    reason = Keyword.get(options, :reason)

    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :payment,
      change_payment(payment, %{"trx_status" => "cancel", "cancellation_reason" => reason})
    )
    |> Ecto.Multi.run(:order, fn
      repo, %{payment: payment} when cancel_order ->
        Repo.preload(payment, :order).order
        |> change_order(%{"status" => "cancelled", "cancellation_reason" => reason})
        |> repo.update()

      _repo, _ ->
        {:ok, nil}
    end)
    |> Ecto.Multi.run(:provider, fn _repo, %{payment: payment} ->
      App.payment_provider().cancel_transaction(payment.id)
    end)
    |> Repo.transaction(timeout: Application.fetch_env!(:app, :db_transaction_timeout))
  end

  @doc """
  Convert GetTransactionResult to payment attributes.
  We also need to make sure that attrs keys are strings not atoms.
  """
  def to_payment_attrs(%GetTransactionResult{} = result) do
    Map.from_struct(result)
    |> Map.put("trx_id", result.id)
    |> Map.put("trx_status", result.status)
    |> Map.put("get_transaction_response", result.data)
    |> Jason.encode!()
    |> Jason.decode!()
  end

  def change_payment_notification(%Plug.Conn{} = conn, payment \\ %App.Orders.Payment{}) do
    PaymentNotification.changeset_from_conn(conn, payment)
  end

  def create_payment_notification(changeset) do
    Repo.insert(changeset)
  end
end
