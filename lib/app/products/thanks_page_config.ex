defmodule App.Products.ThanksPageConfig do
  use Ecto.Schema
  import Ecto.Changeset

  @type_options [
    {"Halaman terima kasih", "message"},
    {"Redirect ke URL", "redirect"}
  ]
  @default_title "Terima kasih!"
  @default_message "Link akses produk sudah dikirimkan ke <b>{{EMAIL}}</b>"
  @fields ~w(type title message redirect_url message_left_aligned show_brand_logo)a

  @primary_key false
  embedded_schema do
    field :version, :string, default: "1"
    field :type, :string, default: "message"
    field :redirect_url, :string
    field :title, :string, default: @default_title
    field :message, :string, default: @default_message
    field :message_left_aligned, :boolean, default: false
    field :show_brand_logo, :boolean, default: false
  end

  def type_options(), do: @type_options

  def changeset(config, %{"type" => "redirect"} = attrs) do
    config
    |> cast(attrs, @fields)
    |> validate_required(~w(type redirect_url)a)
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, @fields)
  end

  def get_or_default(obj) when is_struct(obj) do
    case obj.thanks_page_config do
      nil -> %__MODULE__{}
      config -> config
    end
  end

  def render(config, order) do
    context = %{
      NAMA: order.customer_name,
      EMAIL: order.customer_email,
      PHONE: order.customer_phone
    }

    case config.type do
      "message" ->
        config
        |> Map.put(:title, Mustache.render(config.title, context))
        |> Map.put(:message, Mustache.render(config.message, context))

      "redirect" ->
        config
        |> Map.put(:redirect_url, Mustache.render(config.redirect_url || "", context))
    end
  end
end
