defmodule App.Utils.Commons do
  def delimited_number(number) do
    Number.Delimit.number_to_delimited(number, precision: 0)
  end

  def format_price(price) do
    "Rp. " <> delimited_number(price)
  end
end
