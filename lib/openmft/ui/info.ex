defmodule Openmft.Ui.Info do
  @moduledoc """
  Helpers to introspect `Openmft.Ui` modules.
  """

  alias Openmft.Ui.Form.Action
  alias Spark.Dsl.Extension

  @doc """
  Returns the form fields defined for the given action.
  """
  @spec form_for(Openmft.Ui.t(), atom()) :: Action.t() | nil
  def form_for(ui_module, action_name) do
    ui_module
    |> Extension.get_entities([:form])
    |> Enum.find(fn action ->
      action.name == action_name
    end)
  end

  @doc """
  Returns the data table defined for the given action.
  Uses O(1) persisted lookup map.
  """
  @spec data_table_for(Openmft.Ui.t(), atom()) :: map() | nil
  def data_table_for(ui_module, action_name) do
    ui_module
    |> Extension.get_persisted(:data_table_actions_by_name, %{})
    |> Map.get(action_name)
  end
end
