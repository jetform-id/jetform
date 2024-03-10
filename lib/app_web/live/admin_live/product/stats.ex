defmodule AppWeb.AdminLive.Product.Stats do
  use AppWeb, :live_view

  alias App.Products
  alias App.Orders
  alias AppWeb.AdminLive.Product.Components.Commons

  @result_limit 10
  @default_time_filter "7d"
  @time_filters [
    {"3 hari terakhir", "3d"},
    {"7 hari terakhir", "7d"},
    {"14 hari terakhir", "14d"},
    {"30 hari terakhir", "30d"}
  ]
  @time_filters_map Enum.map(@time_filters, fn {x, y} -> {y, x} end) |> Enum.into(%{})

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    product = Products.get_product!(id)

    socket =
      socket
      |> assign(:page_title, "Statistik #{product.name}")
      |> assign(:product, product)
      |> assign(:time_filters, @time_filters)
      |> assign(:time_filters_map, @time_filters_map)
      |> assign(:status_filter_form, to_form(%{"status" => nil}))
      |> assign(:time_filter_form, to_form(%{"time" => @default_time_filter}))
      |> stream(:orders, [])

    {:ok, socket}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    product_id = socket.assigns.product.id
    params = Map.put(socket.assigns.params, "page", page)

    socket =
      socket
      |> assign(:params, params)
      |> push_patch(to: ~p"/products/#{product_id}/stats?#{params}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("set_time_filter", %{"time" => time}, socket) do
    product_id = socket.assigns.product.id

    params =
      socket.assigns.params
      |> Map.put("page", 1)
      |> Map.put("time", time)

    socket =
      socket
      |> assign(:params, params)
      |> push_patch(to: ~p"/products/#{product_id}/stats?#{params}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_order", %{"status" => status}, socket) do
    product_id = socket.assigns.product.id

    params =
      socket.assigns.params
      |> Map.put("page", 1)
      |> Map.put("status", status)

    socket =
      socket
      |> assign(:params, params)
      |> push_patch(to: ~p"/products/#{product_id}/stats?#{params}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    user = socket.assigns.current_user
    product = socket.assigns.product

    time_filter = Map.get(params, "time", @default_time_filter)
    {start_time, _end_time} = time_range(user, product, time_filter)

    order_stats = Orders.stats_by_product_and_time(product, start_time)
    {orders, pagination} = fetch_orders(user, product, start_time, params)

    orders_with_index =
      orders
      |> Enum.with_index()
      |> Enum.map(fn {order, index} -> Map.put(order, :index, index) end)

    socket =
      socket
      |> assign(:params, Map.drop(params, ["id"]))
      |> assign(:status_filter_form, to_form(%{"status" => Map.get(params, "status")}))
      |> assign(
        :time_filter_form,
        to_form(%{"time" => Map.get(params, "time", @default_time_filter)})
      )
      |> assign(:pagination, pagination)
      |> stream(:orders, orders_with_index, reset: true)
      |> assign(:order_stats, order_stats)
      |> assign(:start_time, start_time)

    {:noreply, socket}
  end

  defp fetch_orders(user, product, start_time, params) do
    query = %{
      order_by: [:inserted_at],
      order_directions: [:desc],
      page_size: @result_limit,
      page: max(Map.get(params, "page", "1") |> String.to_integer(), 1),
      filters: [
        %{field: :product_id, value: product.id},
        %{field: :status, value: Map.get(params, "status")},
        %{field: :inserted_at, op: :>=, value: start_time}
      ]
    }

    Orders.list_orders!(user, query)
  end

  defp time_range(user, _product, range_string) do
    now = Timex.now() |> Timex.to_datetime(user.timezone)

    case range_string do
      "3d" -> {Timex.shift(now, days: -3) |> Timex.beginning_of_day(), now}
      "7d" -> {Timex.shift(now, days: -7) |> Timex.beginning_of_day(), now}
      "14d" -> {Timex.shift(now, days: -14) |> Timex.beginning_of_day(), now}
      "30d" -> {Timex.shift(now, days: -30) |> Timex.beginning_of_day(), now}
      _ -> {Timex.shift(now, days: -7) |> Timex.beginning_of_day(), now}
    end
  end
end
