defmodule App.Users.BrandLogo do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  # To add a thumbnail version:
  @versions [:thumb]

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
  def transform(:thumb, _) do
    {:convert, "-strip -thumbnail 256x256^ -gravity center -extent 256x256 -format png", :png}
  end

  # Override the storage directory:
  def storage_dir(version, {_file, scope}) do
    id = :crypto.hash(:md5, scope.id) |> Base.encode16(case: :lower)
    "uploads/users/#{id}/logo/#{version}"
  end

  def default_url(:thumb, _scope) do
    "https://placehold.co/256x256"
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
