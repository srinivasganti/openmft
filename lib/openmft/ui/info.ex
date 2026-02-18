defmodule Openmft.Ui.Info do
  @moduledoc """
  Helpers to introspect `Openmft.Ui` modules.
  """

  alias Ash.Resource.Relationships.{BelongsTo, HasMany, HasOne, ManyToMany}
  alias Ash.Resource.{Aggregate, Attribute, Calculation, Info}
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

  @doc """
  Get a resource via a relationship path from a starting resource.
  """
  @spec resource_by_path(Ash.Resource.t(), [atom()]) :: Ash.Resource.t()
  def resource_by_path(resource, []), do: resource

  def resource_by_path(resource, [relationship | rest]) do
    case Info.field(resource, relationship) do
      %Aggregate{} -> resource
      %Calculation{} -> resource
      %Attribute{} -> resource
      %BelongsTo{destination: destination} -> resource_by_path(destination, rest)
      %HasOne{destination: destination} -> resource_by_path(destination, rest)
      %HasMany{destination: destination} -> resource_by_path(destination, rest)
      %ManyToMany{destination: destination} -> resource_by_path(destination, rest)
    end
  end
end
