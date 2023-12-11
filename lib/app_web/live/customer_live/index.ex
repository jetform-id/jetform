defmodule AppWeb.CustomerLive.Index do
  use AppWeb, :live_view

  # alias App.Accounts
  # alias App.Accounts.Customer

  # @impl true
  # def mount(_params, _session, socket) do
  #   {:ok, stream(socket, :customers, Accounts.list_customers())}
  # end

  # @impl true
  # def handle_params(params, _url, socket) do
  #   {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  # end

  # defp apply_action(socket, :edit, %{"id" => id}) do
  #   socket
  #   |> assign(:page_title, "Edit Customer")
  #   |> assign(:customer, Accounts.get_customer!(id))
  # end

  # defp apply_action(socket, :new, _params) do
  #   socket
  #   |> assign(:page_title, "New Customer")
  #   |> assign(:customer, %Customer{})
  # end

  # defp apply_action(socket, :index, _params) do
  #   socket
  #   |> assign(:page_title, "Listing Customers")
  #   |> assign(:customer, nil)
  # end

  # @impl true
  # def handle_info({AppWeb.CustomerLive.FormComponent, {:saved, customer}}, socket) do
  #   {:noreply, stream_insert(socket, :customers, customer)}
  # end

  # @impl true
  # def handle_event("delete", %{"id" => id}, socket) do
  #   customer = Accounts.get_customer!(id)
  #   {:ok, _} = Accounts.delete_customer(customer)

  #   {:noreply, stream_delete(socket, :customers, customer)}
  # end
end
