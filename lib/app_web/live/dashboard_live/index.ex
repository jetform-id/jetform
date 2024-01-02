defmodule AppWeb.DashboardLive.Index do
  use AppWeb, :live_view

  alias App.Orders
  alias AppWeb.ProductLive.Components.Commons

  @result_limit 5

  @impl true
  def mount(
        _params,
        _session,
        %{assigns: %{current_user: %{unconfirmed_email: unconfirmed_email}}} = socket
      ) do
    socket =
      case unconfirmed_email do
        nil ->
          socket

        email ->
          socket
          |> put_flash(
            :warning,
            "Click the link in the confirmation email to change your email to #{email}."
          )
      end
      |> assign(:page_title, "Dashboard")
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
