defmodule App.ContentTest do
  use App.DataCase

  alias App.Content

  describe "content_access" do
    alias App.Content.Access

    import App.ContentFixtures

    @invalid_attrs %{valid_until: nil}

    test "list_content_access/0 returns all content_access" do
      access = access_fixture()
      assert Content.list_content_access() == [access]
    end

    test "get_access!/1 returns the access with given id" do
      access = access_fixture()
      assert Content.get_access!(access.id) == access
    end

    test "create_access/1 with valid data creates a access" do
      valid_attrs = %{valid_until: ~U[2024-01-05 05:58:00Z]}

      assert {:ok, %Access{} = access} = Content.create_access(valid_attrs)
      assert access.valid_until == ~U[2024-01-05 05:58:00Z]
    end

    test "create_access/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_access(@invalid_attrs)
    end

    test "update_access/2 with valid data updates the access" do
      access = access_fixture()
      update_attrs = %{valid_until: ~U[2024-01-06 05:58:00Z]}

      assert {:ok, %Access{} = access} = Content.update_access(access, update_attrs)
      assert access.valid_until == ~U[2024-01-06 05:58:00Z]
    end

    test "update_access/2 with invalid data returns error changeset" do
      access = access_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_access(access, @invalid_attrs)
      assert access == Content.get_access!(access.id)
    end

    test "delete_access/1 deletes the access" do
      access = access_fixture()
      assert {:ok, %Access{}} = Content.delete_access(access)
      assert_raise Ecto.NoResultsError, fn -> Content.get_access!(access.id) end
    end

    test "change_access/1 returns a access changeset" do
      access = access_fixture()
      assert %Ecto.Changeset{} = Content.change_access(access)
    end
  end
end
