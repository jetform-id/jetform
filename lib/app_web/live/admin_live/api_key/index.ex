defmodule AppWeb.AdminLive.APIKey.Index do
  use AppWeb, :live_view
  require Logger

  alias App.Users

  @impl true
  def mount(_params, _session, socket) do
    api_keys = Users.list_api_keys(socket.assigns.current_user)

    socket =
      socket
      |> assign(:show_modal, false)
      |> assign(:page_title, "API Keys")
      |> stream(:api_keys, api_keys)

    {:ok, socket}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  @impl true
  def handle_event("new_key", _params, socket) do
    changeset = Users.change_api_key(%Users.APIKey{}, %{"key" => Pow.UUID.generate()})

    socket =
      socket
      |> assign(:show_modal, true)
      |> assign(:form, to_form(changeset))

    {:noreply, socket}
  end

  @impl true
  def handle_event("create_key", %{"api_key" => api_key_params}, socket) do
    params = Map.put(api_key_params, "user", socket.assigns.current_user)

    socket =
      case Users.create_api_key(params) do
        {:ok, api_key} ->
          socket
          |> assign(:show_modal, false)
          |> stream_insert(:api_keys, api_key)
          |> put_flash(:info, "API Key baru berhasil dibuat.")

        {:error, changeset} ->
          socket
          |> put_flash(:error, "Gagal membuat API Key baru.")
          |> assign(:form, to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_key", %{"api_key" => %{"id" => id} = params}, socket) do
    api_key = Users.get_api_key!(id)

    socket =
      case Users.update_api_key(api_key, params) do
        {:ok, api_key} ->
          socket
          |> assign(:show_modal, false)
          |> stream_insert(:api_keys, api_key)
          |> put_flash(:info, "Perubahan API Key berhasil disimpan.")

        {:error, changeset} ->
          socket
          |> put_flash(:error, "Gagal menyimpan perubahan API Key.")
          |> assign(:form, to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("show_key", %{"id" => id}, socket) do
    api_key = Users.get_api_key!(id)
    form = to_form(Users.change_api_key(api_key))

    socket =
      socket
      |> assign(:show_modal, true)
      |> assign(:form, form)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_key", %{"id" => id}, socket) do
    api_key = Users.get_api_key!(id)

    socket =
      case Users.delete_api_key(api_key) do
        {:ok, _} ->
          socket
          |> stream_delete(:api_keys, api_key)
          |> put_flash(:info, "API Key '#{api_key.name}' berhasil dihapus.")

        {:error, _} ->
          socket
          |> put_flash(:error, "Gagal menghapus API Key.")
      end

    {:noreply, socket}
  end
end
