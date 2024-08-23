defmodule App.Products.ImageUploader do
  use Waffle.Definition

  # Include ecto support (requires package waffle_ecto installed):
  use Waffle.Ecto.Definition

  # To add a thumbnail version:
  @versions [:original, :standard, :thumb]

  # Override the bucket on a per definition basis:
  # def bucket do
  #   :custom_bucket_name
  # end

  # def bucket({_file, scope}) do
  #   scope.bucket || bucket()
  # end

  def acl(:standard, _), do: :public_read
  def acl(:thumb, _), do: :public_read

  # Whitelist file extensions:
  def validate({file, _}) do
    file_extension = file.file_name |> Path.extname() |> String.downcase()

    case Enum.member?(~w(.jpg .jpeg .png), file_extension) do
      true -> :ok
      false -> {:error, "invalid file type"}
    end
  end

  # Define a thumbnail transformation:
  def transform(:standard, _) do
    {:convert, "-strip -thumbnail 640x360^ -gravity center -extent 640x360 -format png", :png}
  end

  def transform(:thumb, _) do
    {:convert, "-strip -thumbnail 256x144^ -gravity center -extent 256x144 -format png", :png}
  end

  # Override the persisted filenames:
  # def filename(version, _) do
  #   version
  # end

  # Override the storage directory:
  def storage_dir(version, {_file, %App.Products.Product{}}) do
    "uploads/products/cover/#{version}"
  end

  def storage_dir(version, {_file, %App.Products.Image{} = scope}) do
    "uploads/products/images/#{scope.id}/#{version}"
  end

  # Provide a default URL if there hasn't been a file uploaded
  def default_url(:standard, _scope) do
    "https://via.placeholder.com/640x360"
  end

  def default_url(:thumb, _scope) do
    "https://via.placeholder.com/256x144"
  end

  # Specify custom headers for s3 objects
  # Available options are [:cache_control, :content_disposition,
  #    :content_encoding, :content_length, :content_type,
  #    :expect, :expires, :storage_class, :website_redirect_location]
  #
  # def s3_object_headers(version, {file, scope}) do
  #   [content_type: MIME.from_path(file.file_name)]
  # end
end
