defmodule Openmft.Ui.Dsl.Persisters.Form do
  @moduledoc """
  Persists map data structures for fast access of Form info.
  """

  use Spark.Dsl.Transformer

  alias Openmft.Ui.Form.{Action, Field, FieldGroup}
  alias Spark.Dsl.Transformer

  @doc """
  Runs after all other transformers.
  """
  @spec after?(module()) :: boolean()
  def after?(_), do: true

  @doc """
  Persists Form actions by name and select field metadata for fast lookup.
  """
  @spec transform(Spark.Dsl.t()) :: {:ok, Spark.Dsl.t()}
  def transform(dsl) do
    actions_by_name =
      for %Action{} = action <- Transformer.get_entities(dsl, [:form]), into: %{} do
        {action.name, action}
      end

    select_fields =
      for %Action{} = action <- Transformer.get_entities(dsl, [:form]), into: %{} do
        rel_fields =
          action.fields
          |> collect_relationship_fields()
          |> Map.new(fn field ->
            {field.name, %{relationship: field.relationship, option_label: field.option_label}}
          end)

        {action.name, rel_fields}
      end

    {:ok,
     dsl
     |> Transformer.persist(:form_actions_by_name, actions_by_name)
     |> Transformer.persist(:form_select_fields, select_fields)}
  end

  defp collect_relationship_fields(fields) do
    Enum.flat_map(fields, fn
      %Field{type: :select, relationship: rel} = field when not is_nil(rel) -> [field]
      %FieldGroup{fields: nested} -> collect_relationship_fields(nested)
      _ -> []
    end)
  end
end
