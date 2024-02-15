defmodule AppWeb.AdminLive.Withdrawal.Components.Commons do
  use AppWeb, :html

  attr :status, :atom, required: true

  def status_badge(assigns) do
    ~H"""
    <span
      :if={@status == :pending}
      class="inline-block rounded rounded-full w-3 h-3 me-1 bg-yellow-500"
    >
    </span>
    <span
      :if={@status == :cancelled}
      class="inline-block rounded rounded-full w-3 h-3 me-1 bg-gray-500"
    >
    </span>
    <span
      :if={@status == :submitted}
      class="inline-block rounded rounded-full w-3 h-3 me-1 bg-primary-600"
    >
    </span>
    <span :if={@status == :rejected} class="inline-block rounded rounded-full w-3 h-3 me-1 bg-red-500">
    </span>
    <span
      :if={@status == :success}
      class="inline-block rounded rounded-full w-3 h-3 me-1 bg-green-500"
    >
    </span>
    <%= @status |> Atom.to_string() |> String.upcase() %>
    """
  end
end
