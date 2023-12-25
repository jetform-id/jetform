defmodule AppWeb.ProductLive.Components.Commons do
  use AppWeb, :html

  attr :upload, :map, required: true

  def live_file_error(assigns) do
    ~H"""
    <%= for entry <- @upload.entries do %>
      <%= for err <- upload_errors(@upload, entry) do %>
        <.error :if={err == :too_large}>Ukuran file terlalu besar</.error>
        <.error :if={err == :not_accepted}>Format file tidak sesuai</.error>
        <.error :if={err == :too_many_files}>File terlalu banyak</.error>
      <% end %>
    <% end %>
    """
  end

  attr :changeset, :map, required: true
  attr :on_submit, :string, required: true
  attr :target, :any, required: true

  def variant_form(assigns) do
    assigns =
      case assigns.changeset.data.id do
        nil ->
          assigns
          |> assign(:title, "New Variant")
          |> assign(:btn_text, "Create")
          |> assign(:loading_text, "Creating...")

        _ ->
          assigns
          |> assign(:title, "Edit Variant")
          |> assign(:btn_text, "Update")
          |> assign(:loading_text, "Updating...")
      end

    ~H"""
    <.simple_form
      :let={f}
      for={@changeset}
      as={:variant}
      phx-update="replace"
      phx-submit={@on_submit}
      phx-target={@target}
    >
      <div class="mt-8 space-y-6">
        <div class="grid grid-cols-2 gap-4">
          <.input field={f[:name]} type="text" label="Nama varian" required />
          <.input field={f[:price]} type="number" label="Harga" required>
            <:help>
              <div class="mt-2 text-xs text-gray-500 dark:text-gray-400">
                Masukkan 0 untuk membuat varian ini gratis.
              </div>
            </:help>
          </.input>
        </div>
        <.input field={f[:description]} type="textarea" label="Keterangan" required />

        <%!-- variant settings --%>
        <%!-- <hr class="h-px my-8 bg-gray-200 border-0 dark:bg-gray-700" />
        <div class="flex">
          <div class="flex items-center h-5">
            <input
              id="helper-checkbox"
              aria-describedby="helper-checkbox-text"
              type="checkbox"
              value=""
              class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
            />
          </div>
          <div class="ms-2 text-sm">
            <label for="helper-checkbox" class="font-medium text-gray-900 dark:text-gray-300">
              Batasi jumlah pembelian
            </label>
            <p id="helper-checkbox-text" class="text-xs font-normal text-gray-500 dark:text-gray-300">
              Produk hanya bisa dibeli ketika jumlah pembelian belum mencapai batas tertentu.
            </p>
            <.input field={f[:quantity]} type="number" label="Quantity" />
          </div>
        </div>

        <div class="flex">
          <div class="flex items-center h-5">
            <input
              id="helper-checkbox"
              aria-describedby="helper-checkbox-text"
              type="checkbox"
              value=""
              class="w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
            />
          </div>
          <div class="ms-2 text-sm">
            <label for="helper-checkbox" class="font-medium text-gray-900 dark:text-gray-300">
              Batasi waktu pembelian
            </label>
            <p id="helper-checkbox-text" class="text-xs font-normal text-gray-500 dark:text-gray-300">
              Produk hanya bisa dibeli sampai tanggal tertentu.
            </p>
          </div>
        </div> --%>
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

  attr :id, :string, required: true
  attr :variant, :map, required: true
  attr :on_edit, :string, required: true
  attr :on_delete, :string, required: true
  attr :target, :any, required: true

  def variant_item(assigns) do
    ~H"""
    <div id={@id} class="w-full bg-gray-50 shadow-sm rounded-lg border border-gray-300 p-4">
      <div class="flex mb-4 items-center">
        <span class="flex-1 font-semibold">
          <%= @variant.name %> - Rp. <.price value={@variant.price} />
        </span>
        <span class="flex-none items-center">
          <.button
            phx-click={JS.push(@on_edit, value: %{id: @variant.id}, target: @target)}
            type="button"
            class="text-primary-700 hover:text-white border border-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-2 py-1 text-center dark:border-primary-500 dark:text-primary-500 dark:hover:text-white dark:hover:bg-primary-500 dark:focus:ring-primary-800"
          >
            Edit
          </.button>
          <.button
            phx-click={JS.push(@on_delete, value: %{id: @variant.id}, target: @target)}
            type="button"
            class="text-red-600 hover:text-white border border-red-600 hover:bg-red-600 focus:ring-4 focus:outline-none focus:ring-red-300 font-medium rounded-lg text-sm px-2 py-1 text-center dark:border-red-600 dark:text-red-500 dark:hover:text-white dark:hover:bg-red-500 dark:focus:ring-red-600"
          >
            <.icon name="hero-trash w-4 h-4" />
          </.button>
        </span>
      </div>
      <p class="text-slate-600 text-sm text-sm mt-1 pr-4">
        <%= @variant.description %>
      </p>
      <%!-- <div :if={@variant.quantity} class="pt-2">
          <span class="bg-yellow-100 text-yellow-800 text-xs font-medium inline-flex items-center px-2 py-0.5 rounded dark:bg-gray-700 dark:text-yellow-400 border border-yellow-400">
            <.icon name="hero-clock w-3 h-3 me-1" /> Sisa <%= @variant.quantity %>
          </span>
        </div> --%>
    </div>
    """
  end

  attr :changeset, :map, required: true
  attr :target, :any, required: true
  attr :uploads, :map, required: true
  attr :on_change, :string, required: true
  attr :on_submit, :string, required: true
  attr :on_change_type, :string, required: true

  def content_form(assigns) do
    assigns =
      case assigns.changeset.data.id do
        nil ->
          assigns
          |> assign(:btn_text, "Create")
          |> assign(:loading_text, "Creating...")

        _ ->
          assigns
          |> assign(:btn_text, "Update")
          |> assign(:loading_text, "Updating...")
      end
      |> assign(
        :type,
        Map.get(assigns.changeset.changes, :type, assigns.changeset.data.type)
      )

    ~H"""
    <.simple_form
      :let={f}
      for={@changeset}
      as={:content}
      phx-update="replace"
      phx-change={@on_change}
      phx-submit={@on_submit}
      phx-target={@target}
    >
      <div class="mt-8 space-y-6">
        <.input field={f[:name]} type="text" label="Nama konten" required />
        <.input
          :if={!@changeset.data.id}
          field={f[:type]}
          type="select"
          options={[
            {"URL / Teks", :text},
            {"File", :file}
          ]}
          label="Tipe konten"
          phx-change={@on_change_type}
        />
        <.input :if={@type == :text} field={f[:text]} type="textarea" label="Isi konten">
          <:help>
            <div class="mt-2 text-xs text-gray-500 dark:text-gray-400">
              Anda bisa gunakan untuk membagikan link atau teks.
            </div>
          </:help>
        </.input>

        <%= if @type == :file && @changeset.data.id && !App.Contents.is_empty?(@changeset.data) do %>
          <span class="flex-1 font-semibold flex items-center">
            <.link href={App.Contents.file_url(@changeset.data)} target="_blank">
              <.icon name="hero-paper-clip me-2" /> <%= @changeset.data.file.file_name %>
            </.link>
          </span>
        <% end %>

        <.live_file_error upload={@uploads.file} />
        <.live_file_input :if={@type == :file} upload={@uploads.file} />
        <p :if={@type == :file} class="mt-1 text-sm text-yellow-500">
          <.icon name="hero-hand-raised" />
          Apabila ukuran file anda lebih besar dari 50 MB, kami sarankan anda upload ke layanan penyimpanan pihak ketiga seperti Google Drive atau Dropbox dan gunakan konten tipe URL/Teks untuk mencantumkan link downloadnya.
        </p>
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

  attr :id, :string, required: true
  attr :content, :map, required: true
  attr :target, :any, required: true
  attr :on_edit, :string, required: true
  attr :on_delete, :string, required: true

  def content_item(assigns) do
    ~H"""
    <div id={@id} class="w-full bg-gray-50 shadow-sm rounded-lg border border-gray-300 p-4">
      <div class="flex mb-4 items-center">
        <span class="flex-1 font-semibold flex items-center">
          <%= if @content.type == :text do %>
            <.icon name="hero-document-text me-2" />
          <% else %>
            <.icon name="hero-paper-clip me-2" />
          <% end %>
          <%= @content.name %>
        </span>
        <span class="flex-none items-center">
          <.button
            phx-click={JS.push(@on_edit, value: %{id: @content.id}, target: @target)}
            type="button"
            class="text-primary-700 hover:text-white border border-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-2 py-1 text-center dark:border-primary-500 dark:text-primary-500 dark:hover:text-white dark:hover:bg-primary-500 dark:focus:ring-primary-800"
          >
            Edit
          </.button>
          <.button
            phx-click={JS.push(@on_delete, value: %{id: @content.id}, target: @target)}
            type="button"
            class="text-red-600 hover:text-white border border-red-600 hover:bg-red-600 focus:ring-4 focus:outline-none focus:ring-red-300 font-medium rounded-lg text-sm px-2 py-1 text-center dark:border-red-600 dark:text-red-500 dark:hover:text-white dark:hover:bg-red-500 dark:focus:ring-red-600"
          >
            <.icon name="hero-trash w-4 h-4" />
          </.button>
        </span>
      </div>
      <p class="text-slate-600 text-sm text-sm mt-1 pr-4">
        <%= if @content.type == :text do %>
          <span :if={App.Contents.is_empty?(@content)} class="text-red-600">
            <.icon name="hero-exclamation-triangle-solid" /> Teks masih kosong!
          </span>
          <%= @content.text %>
        <% end %>

        <%= if @content.type == :file do %>
          <%= if !App.Contents.is_empty?(@content) do %>
            <%= @content.file.file_name %>
            <.link href={App.Contents.file_url(@content)} target="_blank">
              <.icon
                name="hero-arrow-top-right-on-square"
                class="w-4 h-4 inline-block text-primary-600 font-bold"
              />
            </.link>
          <% else %>
            <span class="text-red-600">
              <.icon name="hero-exclamation-triangle-solid" /> File masih kosong!
            </span>
          <% end %>
        <% end %>
      </p>
    </div>
    """
  end
end
