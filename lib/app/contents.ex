defmodule App.Contents do
  @moduledoc """
  The Contents context.
  """

  import Ecto.Query, warn: false
  alias App.Repo

  alias App.Contents.Content

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
    %Content{}
    |> Content.create_changeset(attrs)
    |> Repo.insert()
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

  def file_url(content, opts \\ []) do
    App.Contents.ContentFile.url({content.file, content}, :original, opts)
  end
end
