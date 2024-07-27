defmodule AppWeb.AdminLive.Dashboard.Index do
  use AppWeb, :live_view

  alias App.Credits
  alias App.Orders
  alias AppWeb.AdminLive.Product.Components.Commons

  @result_limit 10

  @impl true
  def mount(
        _params,
        _session,
        %{assigns: %{current_user: user}} = socket
      ) do
    end_time = Timex.now()
    start_time = end_time |> Timex.shift(days: -30)

    daily_counts =
      Orders.daily_counts_by_user(user, start_time)
      |> Enum.map(fn {date, x, y} ->
        {Timex.format!(date, "{ISOdate}"), {x, y}}
      end)
      |> Enum.into(%{})

    daily_counts =
      Timex.Interval.new(
        from: start_time,
        until: end_time,
        steps: [days: 1]
      )
      |> Enum.to_list()
      |> Enum.map(fn date ->
        date_str = Timex.format!(date, "{ISOdate}")
        {y1, y2} = Map.get(daily_counts, date_str, {0, 0})
        %{x: date, y1: y1, y2: y2}
      end)
      |> Jason.encode!()

    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:daily_counts, daily_counts)
      |> assign(:top_products, Orders.top_products(user, start_time))
      |> assign(:order_stats, Orders.stats_by_user_and_time(user, start_time))
      |> assign(:withdrawable_credits, Credits.withdrawable_credits_by_user(user))
      |> assign(:pending_credits, Credits.pending_credits_by_user(user))
      |> assign(:status_filter_form, to_form(%{"status" => nil}))
      |> stream(:orders, [])

    {:ok, socket}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    params = Map.put(socket.assigns.params, "page", page)

    socket =
      socket
      |> assign(:params, params)
      |> push_patch(to: ~p"/?#{params}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_order", %{"status" => status}, socket) do
    params =
      socket.assigns.params
      |> Map.put("page", 1)
      |> Map.put("status", status)

    socket =
      socket
      |> assign(:params, params)
      |> push_patch(to: ~p"/?#{params}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {orders, pagination} = fetch_orders(socket.assigns.current_user, params)

    orders_with_index =
      orders
      |> Enum.with_index()
      |> Enum.map(fn {order, index} -> Map.put(order, :index, index) end)

    socket =
      socket
      |> assign(:params, params)
      |> assign(:status_filter_form, to_form(%{"status" => Map.get(params, "status")}))
      |> assign(:pagination, pagination)
      |> stream(:orders, orders_with_index, reset: true)

    {:noreply, socket}
  end

  defp fetch_orders(user, params) do
    query = %{
      order_by: [:inserted_at],
      order_directions: [:desc],
      page_size: @result_limit,
      page: max(Map.get(params, "page", "1") |> String.to_integer(), 1),
      filters: [%{"field" => "status", "value" => Map.get(params, "status")}]
    }

    Orders.list_orders!(user, query)
  end
end
