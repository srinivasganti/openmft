defmodule Openmft.Dsl.Transformers do
  @moduledoc false

  alias Ash.Resource.Info, as: ResourceInfo
  alias Spark.Dsl.Transformer

  @doc """
  Get the Ash resource actions for the DSL.
  """
  def get_resource_actions(dsl) do
    dsl
    |> Transformer.get_persisted(:resource)
    |> ResourceInfo.actions()
  end

  @doc """
  Safely get nested values from maps or keyword lists that may be `nil` at any point.

  ## Examples

      iex> get_nested(nil, [:one, :two, :three])
      nil

      iex> get_nested(%{one: %{two: %{three: 3}}}, [:one, :two, :three])
      3
  """
  def get_nested(value, keys, default \\ nil)
  def get_nested(value, [], _), do: value
  def get_nested(%{} = map, [key], default), do: Map.get(map, key, default)

  def get_nested(%{} = map, [key | keys], default),
    do: get_nested(Map.get(map, key), keys, default)

  def get_nested([_ | _] = keyword, [key], default), do: Keyword.get(keyword, key, default)

  def get_nested([_ | _] = keyword, [key | keys], default),
    do: get_nested(Keyword.get(keyword, key), keys, default)

  def get_nested(_, _, default), do: default

  @doc """
  Extract a default humanized label from an entity name.
  """
  def default_label(%{name: name}), do: default_label(name)
  def default_label(name) when is_atom(name), do: default_label(Atom.to_string(name))

  def default_label(name) when is_binary(name),
    do: name |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)

  @doc """
  Preserve path context when merging nested entities.
  """
  def maybe_append_path(root, []), do: root
  def maybe_append_path(root, path) when not is_nil(path), do: root ++ List.wrap(path)

  defmacro __using__(_env) do
    quote do
      use Spark.Dsl.Transformer

      import unquote(__MODULE__)
    end
  end
end
