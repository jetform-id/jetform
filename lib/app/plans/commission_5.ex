defmodule App.Plans.Commission5 do
  @behaviour App.Plans.Plan

  @id "plan-comm-5"
  @name "JetForm 5"
  @description "JetForm fee = 5% (komisi) + 0.7% (QRIS) per transaksi"
  @commission_percent 5 + 0.7

  def id(), do: @id
  def name(), do: @name
  def description(), do: @description
  def valid_until(_now), do: ~U[9999-12-31 23:59:59Z]
  def commission(value), do: trunc(value * @commission_percent / 100)
end
