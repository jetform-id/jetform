defmodule AppWeb.API.Utils do
  def maybe_put_string_filter(filters, params, field, op \\ :==) do
    maybe_put_filter(filters, params, field, &to_string/1, op)
  end

  def maybe_put_boolean_filter(filters, params, field, op \\ :==) do
    maybe_put_filter(filters, params, field, fn v -> v == "true" end, op)
  end

  def maybe_put_integer_filter(filters, params, field, op \\ :==) do
    maybe_put_filter(filters, params, field, &String.to_integer/1, op)
  end

  def maybe_put_float_filter(filters, params, field, op \\ :==) do
    maybe_put_filter(filters, params, field, &String.to_float/1, op)
  end

  def maybe_put_atom_filter(filters, params, field, op \\ :==) do
    maybe_put_filter(filters, params, field, &String.to_atom/1, op)
  end

  def maybe_put_filter(filters, params, filter, value_transformer_fn, op \\ :==) do
    case Map.get(params, filter) do
      nil ->
        filters

      value ->
        [%{field: String.to_atom(filter), op: op, value: value_transformer_fn.(value)} | filters]
    end
  end

  def set_limit(params, field \\ "limit", max \\ 20) do
    String.to_integer(Map.get(params, field, to_string(max))) |> min(max)
  end

  def transform_flop_meta(meta) do
    Map.take(meta, [
      :total_pages,
      :total_count,
      :current_page,
      :next_page,
      :previous_page,
      :page_size
    ])
  end
end
