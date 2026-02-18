defmodule Openmft.Ui.Dsl.Persisters.Form do
  @moduledoc """
  Persists map data structures for fast access of Form info.
  """

  use Spark.Dsl.Transformer

  alias Openmft.Ui.Form.Action
  alias Spark.Dsl.Transformer

  @doc """
  Runs after all other transformers.
  """
  @spec after?(module()) :: boolean()
  def after?(_), do: true

  @doc """
  Persists Form actions by name for fast lookup.
  """
  @spec transform(Spark.Dsl.t()) :: {:ok, Spark.Dsl.t()}
  def transform(dsl) do
    actions_by_name =
      for %Action{} = action <- Transformer.get_entities(dsl, [:form]), into: %{} do
        {action.name, action}
      end

    {:ok,
     dsl
     |> Transformer.persist(:form_actions_by_name, actions_by_name)}
  end
end
