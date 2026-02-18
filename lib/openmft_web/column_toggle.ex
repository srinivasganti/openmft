defmodule OpenmftWeb.ColumnToggle do
  @moduledoc """
  Shared helpers for column visibility state management in data tables.
  """

  alias Openmft.Ui.Info

  @doc """
  Initializes column toggle assigns from DSL config.

  Returns a keyword list with `:visible_columns` and `:all_columns`.
  """
  @spec init(module(), atom()) :: keyword()
  def init(ui_module, action) do
    config = Info.data_table_for(ui_module, action)
    all_columns = Map.keys(config.columns)
    visible = config.default_display

    [visible_columns: visible, all_columns: all_columns]
  end

  @doc """
  Toggles a column's visibility. Adds it if hidden, removes it if visible.

  Returns the updated `visible_columns` list, preserving `all_columns` order.
  """
  @spec toggle(list(atom()), list(atom()), atom()) :: list(atom())
  def toggle(visible_columns, all_columns, column_name) do
    if column_name in visible_columns do
      List.delete(visible_columns, column_name)
    else
      Enum.filter(all_columns, &(&1 in [column_name | visible_columns]))
    end
  end

  @doc """
  Resets visible columns to the DSL-configured `default_display`.
  """
  @spec restore_defaults(module(), atom()) :: list(atom())
  def restore_defaults(ui_module, action) do
    config = Info.data_table_for(ui_module, action)
    config.default_display
  end
end
