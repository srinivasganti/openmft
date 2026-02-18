defmodule Openmft.Ui.Info do
  @moduledoc """
  Helpers to introspect `Openmft.Ui` modules.
  """

  alias Ash.Resource.Relationships.{BelongsTo, HasMany, HasOne, ManyToMany}
  alias Ash.Resource.{Aggregate, Attribute, Calculation, Info}
  alias Openmft.Ui.Form.Action
  alias Spark.Dsl.Extension

  @doc """
  Returns the form action defined for the given action name.
  Uses O(1) persisted lookup map.
  """
  @spec form_for(Openmft.Ui.t(), atom()) :: Action.t() | nil
  def form_for(ui_module, action_name) do
    ui_module
    |> Extension.get_persisted(:form_actions_by_name, %{})
    |> Map.get(action_name)
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
  Returns persisted relationship select field metadata for the given action.
  Returns a map of `%{field_name => %{relationship: atom, option_label: atom}}`.
  """
  @spec relationship_select_fields(Openmft.Ui.t(), atom()) :: map()
  def relationship_select_fields(ui_module, action_name) do
    ui_module
    |> Extension.get_persisted(:form_select_fields, %{})
    |> Map.get(action_name, %{})
  end

  @doc """
  Loads select options for all relationship select fields in an action.
  Reads destination resources via `Ash.read!` and returns `%{field_name => [{label, value}]}`.

  ## Options

    * `:domain` - The Ash domain to use for reads (required)
  """
  @spec load_select_options(Openmft.Ui.t(), atom(), keyword()) :: map()
  def load_select_options(ui_module, action_name, opts \\ []) do
    domain = Keyword.fetch!(opts, :domain)
    resource = Extension.get_persisted(ui_module, :resource)
    rel_fields = relationship_select_fields(ui_module, action_name)

    for {field_name, %{relationship: rel_name, option_label: label_attr}} <- rel_fields,
        into: %{} do
      rel = Info.relationship(resource, rel_name)
      dest = rel.destination

      records = Ash.read!(dest, domain: domain)

      options =
        Enum.map(records, fn record ->
          {Map.get(record, label_attr), Map.get(record, :id)}
        end)

      {field_name, options}
    end
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
