defmodule AppWeb.AdminLive.Dashboard.Index do
  use AppWeb, :live_view

  alias App.Users
  alias App.Orders
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
      |> assign(:product_sold_this_month, Users.product_sold_this_month(user))
      |> assign(:nett_sales_this_month, Users.nett_sales_this_month(user))
      |> assign(:withdrawable_credits, Users.withdrawable_credits(user, nil))
      |> assign(:pending_credits, Users.pending_credits(user))
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
      |> push_patch(to: ~p"/admin?#{params}", replace: true)

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
      |> push_patch(to: ~p"/admin?#{params}", replace: true)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {orders, page} = fetch_orders(socket.assigns.current_user, params)

    socket =
      socket
      |> assign(:params, params)
      |> assign(:status_filter_form, to_form(%{"status" => Map.get(params, "status")}))
      |> assign(:pagination, page)
      |> stream(:orders, orders, reset: true)

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
