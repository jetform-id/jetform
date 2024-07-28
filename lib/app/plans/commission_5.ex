defmodule App.Plans.Commission5 do
  @behaviour App.Plans.Plan

  @id "plan-comm-5"
  @name "Starter"
  @description "Fee per transaksi = komisi 5% + fee payment gateway"
  @commission_percent 5

  def id(), do: @id
  def name(), do: @name
  def description(), do: @description
  def valid_until(_now), do: ~U[9999-12-31 23:59:59Z]
  def commission(value), do: trunc(value * @commission_percent / 100)
end
