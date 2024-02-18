defmodule App.Plans.Commission75 do
  @behaviour App.Plans.Plan

  @id "plan-comm-7-5"
  @name "JetForm 7,5"
  @description "JetForm fee (komisi) 7,5% per transaksi"
  @commission_percent 7.5

  def id(), do: @id
  def name(), do: @name
  def description(), do: @description
  def valid_until(_now), do: ~U[9999-12-31 23:59:59Z]
  def commission(value), do: trunc(value * @commission_percent / 100)
end
