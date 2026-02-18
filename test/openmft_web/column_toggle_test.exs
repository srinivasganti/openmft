defmodule OpenmftWeb.ColumnToggleTest do
  use ExUnit.Case, async: true

  alias OpenmftWeb.ColumnToggle

  describe "toggle/3" do
    test "removes a visible column" do
      visible = [:name, :email, :phone_number]
      all = [:name, :email, :phone_number, :status]

      assert ColumnToggle.toggle(visible, all, :email) == [:name, :phone_number]
    end

    test "adds a hidden column in DSL-defined order" do
      visible = [:name, :phone_number]
      all = [:name, :email, :phone_number, :status]

      assert ColumnToggle.toggle(visible, all, :email) == [:name, :email, :phone_number]
    end

    test "adds column at end when it is last in all_columns" do
      visible = [:name, :email]
      all = [:name, :email, :phone_number, :status]

      assert ColumnToggle.toggle(visible, all, :status) == [:name, :email, :status]
    end
  end
end
