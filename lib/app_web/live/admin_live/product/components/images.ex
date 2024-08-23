defmodule AppWeb.AdminLive.Product.Components.Images do
  use AppWeb, :live_component
  use AppWeb, :html
  require Logger

  alias App.Products
  alias AppWeb.AdminLive.Product.Components.Commons

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"images-for-product-" <> @id} class="p-4 md:p-8 dark:bg-gray-800 space-y-4">
      <%!-- variant list --%>
      <div id="images-for-product" class="space-y-4" phx-update="stream">
        <div
          :for={{dom_id, image} <- @streams.images}
          id={dom_id}
          class="w-full bg-gray-50 shadow-sm rounded-md border border-gray-300 p-4"
        >
          <div class="flex items-start">
            <img src={Products.image_url(image, :thumb)} class="flex-none w-28" />
            <div class="flex-1 ml-4">
              <p class="font-semibold">
                <%= image.attachment.file_name %>
              </p>
              <p class="text-sm text-slate-500"><%= Products.image_size_kb(image) %></p>
              <p class="text-xs text-primary-500">
                <.link href={Products.image_url(image, :original, signed: true)}>
                  <.icon name="hero-arrow-down-tray" class="w-3 h-3 inline-block text-primary-500" />
                  download
                </.link>
              </p>
            </div>
            <.button
              phx-click={
                JS.push("delete", value: %{id: image.id}, target: @myself, page_loading: true)
              }
              type="button"
              class="flex-none text-red-600 hover:text-white border border-red-600 hover:bg-red-600 focus:ring-4 focus:outline-none focus:ring-red-300 font-medium rounded-md text-sm px-2 py-1 text-center dark:border-red-600 dark:text-red-500 dark:hover:text-white dark:hover:bg-red-500 dark:focus:ring-red-600"
            >
              <.icon name="hero-trash w-4 h-4" />
            </.button>
          </div>
        </div>
      </div>

      <%!-- new image button --%>
      <.simple_form
        :if={@upload_progress == 0}
        for={@changeset}
        phx-change="validate"
        phx-target={@myself}
      >
        <div
          phx-drop-target={@uploads.image.ref}
          role="button"
          tabindex="0"
          class="transition-all p-6 border border-slate-300 rounded-md cursor-pointer focus:outline-none focus:border-primary-600 focus:border-solid hover:border-primary-1000 hover:border-solid border-dashed"
        >
          <label class="flex justify-start cursor-pointer">
            <div class="mr-2">
              <.icon name="hero-photo w-10 h-10 bg-slate-400" />
            </div>
            <div class="">
              <div class="flex text-slate-600">
                <div class="relative cursor-pointer bg-white rounded-md font-medium text-primary-600 hover:text-primary-600 focus-within:outline-none">
                  <.live_file_input upload={@uploads.image} class="hidden" />
                  <span>Klik untuk pilih</span>
                </div>
                <p class="pl-1">atau drag-and-drop gambar disini</p>
              </div>
              <p class="text-sm text-slate-400">
                Disarankan dimensi 1280 x 720 (16:9) dan maksimum 1MB
              </p>
            </div>
          </label>
        </div>
        <Commons.live_file_error upload={@uploads.image} />
      </.simple_form>
      <div :if={@upload_progress > 0}>
        <div class="flex justify-between pt-4 mb-2">
          <span class="flex text-sm font-medium text-slate-500">
            <svg
              aria-hidden="true"
              class="w-4 h-4 me-2 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600"
              viewBox="0 0 100 101"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z"
                fill="currentColor"
              /><path
                d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z"
                fill="currentFill"
              />
            </svg>
            Uploading file...
          </span>
          <span class="text-sm font-medium text-slate-500">
            <%= progress_str(@upload_progress) %>
          </span>
        </div>
        <div class="w-full bg-gray-200 rounded-full h-1.5">
          <div
            class="bg-primary-500 h-1.5 rounded-full"
            style={"width: " <> progress_str(@upload_progress)}
          >
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{product: product} = assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign(:changeset, Products.change_image(%Products.Image{}))
      |> stream(:images, Products.list_images(product))
      |> allow_upload(:image,
        accept: ~w(.jpg .jpeg .png),
        auto_upload: true,
        progress: &handle_progress/3,
        max_file_size: 1_000_000
      )
      |> assign(:upload_progress, 0)

    {:ok, socket}
  end

  @impl true
  def update(%{action: {:upload, entry}}, socket) do
    {path, size} = handle_upload(entry, socket)

    params = %{
      "product" => socket.assigns.product,
      "attachment" => path,
      "attachment_size_byte" => size
    }

    case Products.create_image(params) do
      {:ok, image} ->
        notify_parent()
        {:ok, socket |> stream_insert(:images, image) |> set_progress(0)}

      {:error, changeset} ->
        {:ok, socket |> assign(:changeset, changeset) |> set_progress(0)}
    end
  end

  @impl true
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    image = Products.get_image!(id)

    case Products.delete_image(image) do
      {:ok, _} ->
        notify_parent()
        {:noreply, stream_delete(socket, :images, image)}

      err ->
        Logger.error("Failed to delete image: #{inspect(err)}")
        {:noreply, socket}
    end
  end

  defp handle_progress(:image, entry, socket) do
    progress =
      cond do
        entry.progress < 100 -> entry.progress
        true -> Enum.random(60..90)
      end

    if entry.done? do
      # handle upload later, now we update the UI first
      send_update(__MODULE__, id: socket.assigns.product.id, action: {:upload, entry})
      {:noreply, set_progress(socket, progress)}
    else
      {:noreply, set_progress(socket, progress)}
    end
  end

  defp set_progress(socket, progress) do
    assign(socket, :upload_progress, progress)
  end

  defp progress_str(progress) do
    progress_str = trunc(progress / 100 * 100)
    "#{progress_str}%"
  end

  defp handle_upload(entry, socket) do
    consume_uploaded_entry(socket, entry, fn %{path: path} ->
      ext = String.replace(entry.client_type, "image/", ".")

      filename =
        entry.client_name
        |> Path.rootname()
        |> String.replace(" ", "-")
        |> String.downcase()
        |> then(fn f -> f <> ext end)

      updated_path = Path.join(Path.dirname(path), filename)
      File.cp!(path, updated_path)
      {:ok, {updated_path, entry.client_size}}
    end)
  end

  defp notify_parent() do
    send(self(), :images_updated)
  end
end
