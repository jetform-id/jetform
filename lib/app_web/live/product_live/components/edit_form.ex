defmodule AppWeb.ProductLive.Components.EditForm do
  use AppWeb, :html
  alias App.Products
  alias AppWeb.Utils

  @doc """
  Renders basic product editor form
  """
  attr :on_change, :string, default: "validate"
  attr :on_submit, :string, default: "save"
  attr :product, :map, required: true
  attr :changeset, :map, required: true
  attr :uploads, :map, required: true

  def render(assigns) do
    ~H"""
    <.simple_form
      :let={f}
      for={@changeset}
      phx-update="replace"
      phx-change={@on_change}
      phx-submit={@on_submit}
    >
      <div class="space-y-6">
        <%!-- <.error :if={@changeset.action && not @changeset.valid?}>
              Oops, something went wrong! Please check the errors below.
            </.error> --%>
        <.input field={f[:name]} type="text" label="Name" required />
        <.input field={f[:is_live]} type="checkbox" label="Is live?" />
        <.input field={f[:slug]} type="text" label="URL" required>
          <:help>
            <div class="mt-2 text-xs text-gray-500 dark:text-gray-400">
              <%= Utils.base_url() %>/p/<span id="shop-username" class="font-bold"><%= Map.get(@changeset.changes, :slug, @changeset.data.slug) %></span>
            </div>
          </:help>
        </.input>
        <.input field={f[:price]} type="number" label="Price" required />
        <.input field={f[:description]} type="textarea" label="Description" />
        <.input
          field={f[:cta]}
          type="select"
          label="Call To Action (CTA)"
          options={App.Products.cta_options()}
          required
        />
        <.input
          :if={Map.get(@changeset.changes, :cta, @changeset.data.cta) != :custom}
          field={f[:cta_text]}
          type="text"
          rest_class="hidden"
        />
        <.input
          :if={Map.get(@changeset.changes, :cta, @changeset.data.cta) == :custom}
          field={f[:cta_text]}
          type="text"
          placeholder="Custom CTA..."
          required
        />
        <.details_input details={f[:details]} />
        <img src={Products.cover_url(@product, :standard)} />
        <.live_file_input upload={@uploads[:cover]} />
      </div>

      <:actions>
        <div class="mt-8">
          <.button
            phx-disable-with="Saving..."
            class="w-full px-5 py-3 text-base font-medium text-center text-white bg-primary-700 rounded-lg hover:bg-primary-800 focus:ring-4 focus:ring-primary-300 sm:w-auto dark:bg-primary-600 dark:hover:bg-primary-700 dark:focus:ring-primary-800"
          >
            Save <span aria-hidden="true">→</span>
          </.button>
        </div>
      </:actions>
    </.simple_form>
    """
  end

  attr :label, :string, default: "Details"
  attr :details, :map, required: true
  attr :on_add, :string, default: "add_detail"
  attr :on_change, :string, default: "update_detail"
  attr :on_delete, :string, default: "delete_detail"

  def details_input(assigns) do
    ~H"""
    <div phx-feedback-for="details">
      <.label><%= @label %></.label>
      <div
        :for={%{"id" => id, "key" => key, "value" => value} = detail <- @details.value["items"]}
        class="flex flex-row gap-2 w-full"
      >
        <.input
          name={"detail_key_"  <> id}
          type="text"
          placeholder="Nama detail"
          value={key}
          wrapper_class="flex-1"
          phx-change={@on_change}
        />
        <span class="flex-none inline-flex items-center">=</span>
        <.input
          name={"detail_value_"  <> id}
          type="text"
          placeholder="Value detail"
          value={value}
          wrapper_class="flex-1"
          phx-change={@on_change}
        />
        <.link
          phx-click={JS.push(@on_delete, value: detail)}
          class="flex-none inline-flex items-center font-medium text-center text-red-600"
        >
          <.icon name="hero-trash-solid w-5 h-5" />
        </.link>
      </div>

      <.button
        phx-click={@on_add}
        type="button"
        class="mt-2 w-full text-primary-700 hover:text-white border border-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2 text-center me-2 mb-2 dark:border-primary-500 dark:text-primary-500 dark:hover:text-white dark:hover:bg-primary-500 dark:focus:ring-primary-800"
      >
        <.icon name="hero-plus-small w-4 h-4" />Tambah detail
      </.button>
    </div>
    """
  end
end
