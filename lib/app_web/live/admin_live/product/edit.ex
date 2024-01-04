defmodule AppWeb.AdminLive.Product.Edit do
  use AppWeb, :live_view
  alias App.Products
  alias AppWeb.AdminLive.Product.Components.{EditForm, Preview}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    socket =
      case Products.get_product(id) do
        nil ->
          socket
          |> put_flash(:error, "Product not found.")
          |> redirect(to: ~p"/admin/products")

        product ->
          socket
          |> assign(:page_title, "Edit: #{product.name}")
          |> assign(:product, App.Repo.preload(product, :variants))
          |> assign(:changeset, Products.change_product(product, %{}))
          |> allow_upload(:cover, accept: ~w(.jpg .jpeg .png), max_file_size: 1_000_000)
          |> assign(:action, ~p"/admin/products")
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.product
      |> Products.change_product(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"product" => product_params}, socket) do
    # set details changes
    # TODO: handle details on client side
    product_params =
      case Map.get(socket.assigns.changeset.changes, :details) do
        nil -> product_params
        details -> Map.put(product_params, "details", details)
      end

    # get uploaded cover image
    product_params = maybe_put_file_params(socket, product_params, :cover)

    socket =
      case Products.update_product(socket.assigns.product, product_params) do
        {:ok, product} ->
          socket
          |> assign(:product, product)
          |> assign(:changeset, Products.change_product(product, %{}))
          |> put_flash(:info, "Product updated successfully.")

        {:error, changeset} ->
          socket
          |> assign(changeset: changeset)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("add_detail", _params, socket) do
    {:noreply,
     assign(
       socket,
       :changeset,
       Products.add_detail(socket.assigns.product, socket.assigns.changeset)
     )}
  end

  @impl true
  def handle_event("delete_detail", detail, socket) do
    {:noreply,
     assign(
       socket,
       :changeset,
       Products.delete_detail(socket.assigns.product, socket.assigns.changeset, detail)
     )}
  end

  @impl true
  def handle_event(
        "update_detail",
        %{"_target" => [target]} = params,
        socket
      ) do
    ["detail", type, id] = String.split(target, "_")

    changeset =
      Products.update_detail(
        socket.assigns.product,
        socket.assigns.changeset,
        id,
        type,
        params[target]
      )

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_params(%{"tab" => "variants"}, _uri, socket) do
    socket =
      socket |> assign(:tab, "variants")

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"tab" => "content"}, _uri, socket) do
    socket =
      socket |> assign(:tab, "content")

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    socket =
      socket |> assign(:tab, "info")

    {:noreply, socket}
  end

  # handle messages from Variants component

  @impl true
  def handle_info({AppWeb.AdminLive.Product.Components.Variants, :variants_updated}, socket) do
    product =
      socket.assigns.product
      |> App.Repo.reload!()
      |> App.Repo.preload(:variants)

    {:noreply, assign(socket, :product, product)}
  end

  # handle messages from Preview component

  @impl true
  def handle_info({AppWeb.AdminLive.Product.Components.Preview, _order}, socket) do
    {:noreply, put_flash(socket, :info, "Anda dalam mode preview.")}
  end

  defp maybe_put_file_params(socket, params, field) when is_atom(field) do
    case uploaded_entries(socket, field) do
      {[_ | _], []} ->
        [file_path] = uploaded_image_paths(socket, field)
        Map.put(params, Atom.to_string(field), file_path)

      _ ->
        params
    end
  end

  defp uploaded_image_paths(socket, field) when is_atom(field) do
    consume_uploaded_entries(socket, field, fn %{path: path}, entry ->
      extension = String.replace(entry.client_type, "image/", ".")
      updated_path = Path.join(Path.dirname(path), "#{entry.uuid}#{extension}")
      File.cp!(path, updated_path)
      {:ok, updated_path}
    end)
  end
end
