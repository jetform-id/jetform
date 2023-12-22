defmodule AppWeb.ProductLive.Components.Versions do
  use AppWeb, :live_component
  use AppWeb, :html

  alias App.Products

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"product-" <> @id}>
      <%!-- version list --%>
      <div
        :for={version <- @product.versions}
        class="mb-2 w-full rounded-lg border border-gray-300 p-4"
      >
        <div class="flex mb-4">
          <span class="flex-1 items-center mt-2 font-semibold"><%= version.name %></span>
          <span class="flex-none items-center">
            <.button
              phx-click={JS.push("edit", value: %{id: version.id}, target: @myself)}
              type="button"
              class="text-primary-700 hover:text-white border border-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-2 py-1 text-center dark:border-primary-500 dark:text-primary-500 dark:hover:text-white dark:hover:bg-primary-500 dark:focus:ring-primary-800"
            >
              Edit
            </.button>
            <.button
              phx-click={JS.push("delete", value: %{id: version.id}, target: @myself)}
              type="button"
              class="text-red-600 hover:text-white border border-red-600 hover:bg-red-600 focus:ring-4 focus:outline-none focus:ring-red-300 font-medium rounded-lg text-sm px-2 py-1 text-center dark:border-red-600 dark:text-red-500 dark:hover:text-white dark:hover:bg-red-500 dark:focus:ring-red-600"
            >
              <.icon name="hero-trash w-4 h-4" />
            </.button>
          </span>
        </div>
        <p class="text-slate-600 text-sm text-sm mt-1 pr-4">
          <%= version.description %>
        </p>
      </div>

      <%!-- new version button --%>
      <.button
        phx-click={JS.push("new", target: @myself)}
        type="button"
        class="mt-2 w-full text-primary-700 hover:text-white border border-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-4 text-center me-2 mb-2 dark:border-primary-500 dark:text-primary-500 dark:hover:text-white dark:hover:bg-primary-500 dark:focus:ring-primary-800"
      >
        <.icon name="hero-plus-small w-4 h-4" />Buat Varian Produk
      </.button>

      <%!-- new and edit modal --%>
      <.modal :if={@show_modal} id="detail-modal" show on_cancel={JS.push("cancel", target: @myself)}>
        <.version_form changeset={@changeset} target={@myself} />
      </.modal>
    </div>
    """
  end

  attr :changeset, :map, required: true
  attr :target, :any, required: true

  def version_form(assigns) do
    assigns =
      case assigns.changeset.data.id do
        nil ->
          assigns
          |> assign(:action, "create")
          |> assign(:title, "New Version")
          |> assign(:btn_text, "Create")
          |> assign(:loading_text, "Creating...")

        _ ->
          assigns
          |> assign(:action, "update")
          |> assign(:title, "Edit Version")
          |> assign(:btn_text, "Update")
          |> assign(:loading_text, "Updating...")
      end

    ~H"""
    <.simple_form
      :let={f}
      for={@changeset}
      as={:version}
      phx-update="replace"
      phx-submit={@action}
      phx-target={@target}
    >
      <div class="mt-8 space-y-6">
        <.input field={f[:name]} type="text" label="Name" required />
        <.input field={f[:description]} type="textarea" label="Description" />
        <div class="grid grid-cols-2 gap-4">
          <.input field={f[:price]} type="number" label="Price" required />
          <.input field={f[:quantity]} type="number" label="Quantity" />
        </div>
      </div>

      <:actions>
        <div class="mt-8">
          <.button
            phx-disable-with={@loading_text}
            class="w-full px-5 py-3 text-base font-medium text-center text-white bg-primary-700 rounded-lg hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 sm:w-auto dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
          >
            <%= @btn_text %>
            <span aria-hidden="true">→</span>
          </.button>
        </div>
      </:actions>
    </.simple_form>
    """
  end

  @impl true
  def update(assigns, socket) do
    product = assigns.product
    versions = product.versions |> Enum.sort_by(& &1.inserted_at, :asc)

    socket =
      socket
      |> assign(assigns)
      |> assign(:product, product |> Map.put(:versions, versions))
      |> assign(:show_modal, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("new", _params, socket) do
    socket =
      socket
      |> assign(:changeset, Products.change_version(%Products.Version{}, %{}))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    socket =
      socket
      |> assign(:show_modal, false)

    {:noreply, socket}
  end

  @impl true
  def handle_event("create", %{"version" => version_params}, socket) do
    params = Map.put(version_params, "product", socket.assigns.product)

    case Products.create_version(params) do
      {:ok, version} ->
        notify_parent(:create, version)

        socket =
          socket
          |> assign(:show_modal, false)
          |> assign(:changeset_id, nil)
          |> assign(:changeset, nil)

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("update", %{"version" => version_params}, socket) do
    with %{} = version <- Products.get_version(socket.assigns.changeset_id),
         {:ok, version} <- Products.update_version(version, version_params) do
      notify_parent(:update, version)

      socket =
        socket
        |> assign(:show_modal, false)
        |> assign(:changeset_id, nil)
        |> assign(:changeset, nil)

      {:noreply, socket}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    changeset = Products.get_version(id) |> Products.change_version(%{})

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:changeset_id, id)
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    version = Products.get_version(id)
    Products.delete_version(version)
    notify_parent(:delete, version)
    {:noreply, socket}
  end

  defp notify_parent(event, version) do
    send(self(), {__MODULE__, event, version})
  end
end
