defmodule AppWeb.AdminLive.Dashboard.Index do
  use AppWeb, :live_view

  alias App.{Orders, Credits}
  alias AppWeb.AdminLive.Product.Components.Commons

  @result_limit 10

  @impl true
  def mount(
        _params,
        _session,
        %{assigns: %{current_user: user}} = socket
      ) do
    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:month_sales_count, Orders.count_by_user_month(user))
      |> assign(:month_sales_amount, Orders.amount_by_user_month(user))
      |> assign(:withdrawable_credits, Credits.withdrawable_credits_by_user(user, nil))
      |> assign(:pending_credits, Credits.pending_credits_by_user(user))
      |> stream(:orders, [])

    {:ok, socket}
  end

  @impl true
  def handle_event("change_page", %{"page" => page}, socket) do
    params = Map.put(socket.assigns.params, "page", page)

    socket =
      socket
      |> assign(:params, params)
      |> push_patch(to: ~p"/admin?#{params}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    IO.inspect(params)
    {orders, page} = fetch_orders(socket.assigns.current_user, params)

    socket =
      socket
      |> assign(:params, params)
      |> assign(:pagination, page)
      |> stream(:orders, orders, reset: true)

    {:noreply, socket}
  end

  defp fetch_orders(user, params) do
    query = %{
      order_by: [:inserted_at],
      order_directions: [:desc],
      page_size: @result_limit,
      page: max(Map.get(params, "page", "1") |> String.to_integer(), 1)
    }

    Orders.list_orders!(user, query)
  end
end
