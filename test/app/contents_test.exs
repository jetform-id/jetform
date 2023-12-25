defmodule App.ContentsTest do
  use App.DataCase

  alias App.Contents

  describe "contents" do
    alias App.Contents.Content

    import App.ContentsFixtures

    @invalid_attrs %{}

    test "list_contents/0 returns all contents" do
      content = content_fixture()
      assert Contents.list_contents() == [content]
    end

    test "get_content!/1 returns the content with given id" do
      content = content_fixture()
      assert Contents.get_content!(content.id) == content
    end

    test "create_content/1 with valid data creates a content" do
      valid_attrs = %{}

      assert {:ok, %Content{} = content} = Contents.create_content(valid_attrs)
    end

    test "create_content/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Contents.create_content(@invalid_attrs)
    end

    test "update_content/2 with valid data updates the content" do
      content = content_fixture()
      update_attrs = %{}

      assert {:ok, %Content{} = content} = Contents.update_content(content, update_attrs)
    end

    test "update_content/2 with invalid data returns error changeset" do
      content = content_fixture()
      assert {:error, %Ecto.Changeset{}} = Contents.update_content(content, @invalid_attrs)
      assert content == Contents.get_content!(content.id)
    end

    test "delete_content/1 deletes the content" do
      content = content_fixture()
      assert {:ok, %Content{}} = Contents.delete_content(content)
      assert_raise Ecto.NoResultsError, fn -> Contents.get_content!(content.id) end
    end

    test "change_content/1 returns a content changeset" do
      content = content_fixture()
      assert %Ecto.Changeset{} = Contents.change_content(content)
    end
  end
end
