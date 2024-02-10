defmodule App.Plans do
  alias App.Plans

  @plans %{
    Plans.Commission5.id() => Plans.Commission5,
    Plans.Commission10.id() => Plans.Commission10
  }

  def get(id), do: @plans[id]
end
