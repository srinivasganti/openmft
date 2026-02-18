defmodule Openmft.Dsl.Type do
  @moduledoc """
  Custom Spark types for Openmft.
  """

  @css_class {:or, [nil, :string, {:fun, [:map], :string}]}

  @doc """
  Extra CSS classes. Will be appended to base classes. If a function, it will be passed the component assigns.
  """
  def css_class, do: @css_class

  @doc """
  Inheritable types will inherit from parent DSL if not defined, falling back to the Ash resource DSL where applicable.
  """
  def inheritable(type), do: {:or, [type, {:one_of, [:inherit]}]}
end
