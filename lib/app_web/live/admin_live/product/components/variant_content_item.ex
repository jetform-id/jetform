defmodule AppWeb.AdminLive.Product.Components.VariantContentItem do
  use AppWeb, :live_component
  use AppWeb, :html

  alias App.Contents
  alias AppWeb.AdminLive.Product.Components.Commons

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={"content-for-variant-" <> @id}
      class="w-full bg-gray-50 shadow-sm rounded-lg border border-gray-300 p-4"
    >
      <div class="flex mb-4 items-center">
        <span class="flex-1 font-semibold">
          <span class="text-gray-500 font-normal">Konten</span> <%= @variant.name %>
        </span>
        <span class="flex-none items-center">
          <.button
            phx-click={JS.push("new", target: @myself)}
            type="button"
            class="px-2 py-1 bg-primary-600 hover:bg-primary-700 rounded-lg text-white text-sm text-center"
          >
            + Tambah konten
          </.button>
        </span>
      </div>

      <%!-- <div>
          <hr />
          <p class="text-gray-500 text-sm py-2">Belum ada konten.</p>
        </div> --%>

      <%!-- content list --%>
      <div id="content-list-for-variant" phx-update="stream" class="space-y-2">
        <Commons.content_item_mini
          :for={{dom_id, item} <- @streams.content}
          id={dom_id}
          content={item}
          on_edit="edit"
          on_delete="delete"
          target={@myself}
        />
      </div>

      <%!-- new and edit modal --%>
      <.modal
        :if={@show_modal}
        id={"variant-content-modal" <> @id}
        show
        on_cancel={JS.push("cancel", target: @myself)}
      >
        <Commons.content_form
          changeset={@changeset}
          uploads={@uploads}
          target={@myself}
          on_change="validate"
          on_submit="save"
          on_change_type="type_changed"
        />
      </.modal>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> stream(:content, Contents.list_contents_by_variant(assigns.variant))
      |> assign(:show_modal, false)
      |> allow_upload(:file, accept: :any, max_file_size: 50_000_000)

    {:ok, socket}
  end

  @impl true
  def handle_event("new", _params, socket) do
    socket =
      socket
      |> assign(:changeset, Contents.change_content(%Contents.Content{}, %{type: :file}))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _params, socket) do
    {:noreply, close_modal(socket)}
  end

  @impl true
  def handle_event("type_changed", %{"content" => %{"type" => type}}, socket) do
    socket =
      assign(
        socket,
        :changeset,
        socket.assigns.changeset |> Ecto.Changeset.put_change(:type, String.to_atom(type))
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"content" => content_params}, socket) do
    changeset =
      socket.assigns.changeset.data
      |> Contents.change_content(content_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    content = Contents.get_content!(id)

    case Contents.soft_delete_content(content) do
      {:ok, _} ->
        {:noreply, stream_delete(socket, :content, content)}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    content = Contents.get_content!(id)

    socket =
      socket
      |> assign(:changeset, Contents.change_content(content))
      |> assign(:show_modal, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"content" => content_params}, socket) do
    # get uploaded file
    content_params = maybe_put_file_params(socket, content_params, :file)

    case socket.assigns.changeset.data.id do
      nil -> create_content(socket, content_params)
      _id -> update_content(socket, socket.assigns.changeset.data, content_params)
    end
  end

  defp create_content(socket, params) do
    params =
      params
      |> Map.put("product", socket.assigns.product)
      |> Map.put("product_variant", socket.assigns.variant)

    case Contents.create_content(params) do
      {:ok, content} ->
        socket =
          socket
          |> stream_insert(:content, content)
          |> close_modal()

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp update_content(socket, content, params) do
    case Contents.update_content(content, params) do
      {:ok, content} ->
        socket =
          socket
          |> stream_insert(:content, content)
          |> close_modal()

        {:noreply, socket}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp close_modal(socket) do
    socket
    |> assign(:show_modal, false)
    |> assign(:changeset, nil)
  end

  defp maybe_put_file_params(socket, params, field) when is_atom(field) do
    case uploaded_entries(socket, field) do
      {[_ | _], []} ->
        [file_path] = uploaded_file_paths(socket, field)
        Map.put(params, Atom.to_string(field), file_path)

      _ ->
        params
    end
  end

  defp uploaded_file_paths(socket, field) when is_atom(field) do
    consume_uploaded_entries(socket, field, fn %{path: path}, entry ->
      updated_path = Path.join(Path.dirname(path), entry.client_name)
      File.cp!(path, updated_path)
      {:ok, updated_path}
    end)
  end
end
