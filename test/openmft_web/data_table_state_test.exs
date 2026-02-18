defmodule OpenmftWeb.DataTableStateTest do
  use ExUnit.Case, async: true

  alias OpenmftWeb.DataTableState

  describe "cycle_sort/3" do
    setup do
      columns_map = %{
        name: %{name: :name, sortable?: true},
        status: %{name: :status, sortable?: true},
        id: %{name: :id, sortable?: false}
      }

      %{columns: columns_map}
    end

    test "none -> asc", %{columns: columns} do
      assert DataTableState.cycle_sort([], :name, columns) == [name: :asc]
    end

    test "asc -> desc", %{columns: columns} do
      assert DataTableState.cycle_sort([name: :asc], :name, columns) == [name: :desc]
    end

    test "desc -> none", %{columns: columns} do
      assert DataTableState.cycle_sort([name: :desc], :name, columns) == []
    end

    test "sorting a different column replaces current sort", %{columns: columns} do
      assert DataTableState.cycle_sort([name: :asc], :status, columns) == [status: :asc]
    end

    test "non-sortable column is ignored", %{columns: columns} do
      assert DataTableState.cycle_sort([name: :asc], :id, columns) == [name: :asc]
    end
  end

  describe "sort_direction/2" do
    test "returns direction for sorted column" do
      assert DataTableState.sort_direction([name: :asc], :name) == :asc
      assert DataTableState.sort_direction([name: :desc], :name) == :desc
    end

    test "returns nil for unsorted column" do
      assert DataTableState.sort_direction([name: :asc], :email) == nil
      assert DataTableState.sort_direction([], :name) == nil
    end
  end
end
