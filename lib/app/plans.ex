defmodule App.Plans do
  alias App.Plans

  @plans %{
    Plans.Commission5.id() => Plans.Commission5
  }

  def get(id), do: @plans[id]
end
