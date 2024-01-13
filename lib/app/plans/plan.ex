defmodule App.Plans.Plan do
  @callback id :: String.t()
  @callback name :: String.t()
  @callback description :: String.t()
  @callback valid_until(DateTime.t()) :: DateTime.t()
  @callback commission(integer()) :: integer()
end
