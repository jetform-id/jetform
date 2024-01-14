defmodule App.Contents do
  @moduledoc """
  The Contents context.
  """

  import Ecto.Query, warn: false
  alias App.Repo

  alias App.Contents.{Content, Access}

  defdelegate is_empty?(content), to: Content

  @doc """
  Returns the list of contents.

  ## Examples

      iex> list_contents()
      [%Content{}, ...]

  """
  def list_contents do
    Repo.all(Content)
  end

  def list_contents_by_product(product, is_deleted \\ false) do
    Repo.all(
      from c in Content,
        where: c.product_id == ^product.id,
        where: c.is_deleted == ^is_deleted,
        order_by: [asc: c.inserted_at]
    )
  end

  def list_contents_by_variant(variant, is_deleted \\ false) do
    Repo.all(
      from c in Content,
        where: c.product_variant_id == ^variant.id,
        where: c.is_deleted == ^is_deleted,
        order_by: [asc: c.inserted_at]
    )
  end

  @doc """
  Gets a single content.

  Raises `Ecto.NoResultsError` if the Content does not exist.

  ## Examples

      iex> get_content!(123)
      %Content{}

      iex> get_content!(456)
      ** (Ecto.NoResultsError)

  """
  def get_content!(id), do: Repo.get!(Content, id)

  @doc """
  Creates a content.

  ## Examples

      iex> create_content(%{field: value})
      {:ok, %Content{}}

      iex> create_content(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_content(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:content, Content.create_changeset(%Content{}, attrs))
    |> Ecto.Multi.update(:content_with_attachment, fn %{content: content} ->
      Content.attachment_changeset(content, attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{content_with_attachment: content}} ->
        {:ok, content}

      {:error, _op, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a content.

  ## Examples

      iex> update_content(content, %{field: new_value})
      {:ok, %Content{}}

      iex> update_content(content, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_content(%Content{} = content, attrs) do
    content
    |> Content.changeset(attrs)
    |> Content.attachment_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a content.

  ## Examples

      iex> delete_content(content)
      {:ok, %Content{}}

      iex> delete_content(content)
      {:error, %Ecto.Changeset{}}

  """
  def delete_content(%Content{} = content) do
    Repo.delete(content)
  end

  def soft_delete_content(%Content{} = content) do
    content
    |> Content.changeset(%{"is_deleted" => true})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking content changes.

  ## Examples

      iex> change_content(content)
      %Ecto.Changeset{data: %Content{}}

  """
  def change_content(%Content{} = content, attrs \\ %{}) do
    Content.changeset(content, attrs)
  end

  def file_url(content, opts \\ [signed: true]) do
    App.Contents.ContentFile.url({content.file, content}, :original, opts)
  end

  # ---------------- Access ----------------

  defdelegate access_is_valid?(access), to: Access, as: :is_valid?

  @doc """
  Returns the list of content_access.

  ## Examples

      iex> list_content_access()
      [%Access{}, ...]

  """
  def list_content_access do
    Repo.all(Access)
  end

  @doc """
  Gets a single access.

  Raises `Ecto.NoResultsError` if the Access does not exist.

  ## Examples

      iex> get_access!(123)
      %Access{}

      iex> get_access!(456)
      ** (Ecto.NoResultsError)

  """
  def get_access!(id), do: Repo.get!(Access, id)
  def get_access(id), do: Repo.get(Access, id)

  @doc """
  Creates a access.

  ## Examples

      iex> create_access(%{field: value})
      {:ok, %Access{}}

      iex> create_access(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_access(changeset) do
    Repo.insert(changeset)
  end

  @doc """
  Updates a access.

  ## Examples

      iex> update_access(access, %{field: new_value})
      {:ok, %Access{}}

      iex> update_access(access, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_access(%Access{} = access, attrs) do
    access
    |> Access.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a access.

  ## Examples

      iex> delete_access(access)
      {:ok, %Access{}}

      iex> delete_access(access)
      {:error, %Ecto.Changeset{}}

  """
  def delete_access(%Access{} = access) do
    Repo.delete(access)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking access changes.

  ## Examples

      iex> change_access(access)
      %Ecto.Changeset{data: %Access{}}

  """
  def change_access(%Access{} = access, attrs \\ %{}) do
    Access.changeset(access, attrs)
  end

  def create_changeset_for_order(order) do
    access_validity_days = Application.fetch_env!(:app, :access_validity_days)

    Access.create_changeset(%Access{}, %{
      "order" => order,
      "valid_until" => Timex.shift(Timex.now(), days: access_validity_days)
    })
  end
end
