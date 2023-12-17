defmodule AppWeb.ProductLive.Components.Details do
  use AppWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-feedback-for="details">
      <.label for={@id}><%= @label %></.label>
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
          phx-change="update_detail"
        />
        <span class="flex-none inline-flex items-center">=</span>
        <.input
          name={"detail_value_"  <> id}
          type="text"
          placeholder="Value detail"
          value={value}
          wrapper_class="flex-1"
          phx-change="update_detail"
        />
        <.link
          phx-click={JS.push("delete_detail", value: detail)}
          class="flex-none inline-flex items-center font-medium text-center text-red-600"
        >
          <.icon name="hero-trash-solid w-5 h-5" />
        </.link>
      </div>

      <.button
        phx-click="add_detail"
        type="button"
        class="mt-2 w-full text-primary-700 hover:text-white border border-primary-700 hover:bg-primary-800 focus:ring-4 focus:outline-none focus:ring-primary-300 font-medium rounded-lg text-sm px-5 py-2 text-center me-2 mb-2 dark:border-primary-500 dark:text-primary-500 dark:hover:text-white dark:hover:bg-primary-500 dark:focus:ring-primary-800"
      >
        <.icon name="hero-plus-small w-4 h-4" />Tambah detail
      </.button>
    </div>
    """
  end
end
