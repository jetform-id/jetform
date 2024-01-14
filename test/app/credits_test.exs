defmodule App.CreditsTest do
  use App.DataCase

  alias App.Credits

  describe "credits" do
    alias App.Credits.Credit

    import App.CreditsFixtures

    @invalid_attrs %{withdrawable_at: nil}

    test "list_credits/0 returns all credits" do
      credit = credit_fixture()
      assert Credits.list_credits() == [credit]
    end

    test "get_credit!/1 returns the credit with given id" do
      credit = credit_fixture()
      assert Credits.get_credit!(credit.id) == credit
    end

    test "create_credit/1 with valid data creates a credit" do
      valid_attrs = %{withdrawable_at: ~U[2024-01-13 05:23:00Z]}

      assert {:ok, %Credit{} = credit} = Credits.create_credit(valid_attrs)
      assert credit.withdrawable_at == ~U[2024-01-13 05:23:00Z]
    end

    test "create_credit/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Credits.create_credit(@invalid_attrs)
    end

    test "update_credit/2 with valid data updates the credit" do
      credit = credit_fixture()
      update_attrs = %{withdrawable_at: ~U[2024-01-14 05:23:00Z]}

      assert {:ok, %Credit{} = credit} = Credits.update_credit(credit, update_attrs)
      assert credit.withdrawable_at == ~U[2024-01-14 05:23:00Z]
    end

    test "update_credit/2 with invalid data returns error changeset" do
      credit = credit_fixture()
      assert {:error, %Ecto.Changeset{}} = Credits.update_credit(credit, @invalid_attrs)
      assert credit == Credits.get_credit!(credit.id)
    end

    test "delete_credit/1 deletes the credit" do
      credit = credit_fixture()
      assert {:ok, %Credit{}} = Credits.delete_credit(credit)
      assert_raise Ecto.NoResultsError, fn -> Credits.get_credit!(credit.id) end
    end

    test "change_credit/1 returns a credit changeset" do
      credit = credit_fixture()
      assert %Ecto.Changeset{} = Credits.change_credit(credit)
    end
  end
end
