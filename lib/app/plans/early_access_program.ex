defmodule App.Plans.EarlyAccessProgram do
  @behaviour App.Plans.Plan

  @id "plan-eap-1"
  @name "Early Access Program"
  @description "Fee per transaksi = komisi 1% + payment gateway fee"
  @commission_percent 1

  def id(), do: @id
  def name(), do: @name
  def description(), do: @description
  def valid_until(now), do: Timex.shift(now, days: 365)
  def commission(value), do: trunc(value * @commission_percent / 100)
end
