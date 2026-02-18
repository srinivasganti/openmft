defmodule Openmft.Dsl.Type do
  @moduledoc """
  Custom Spark types for Openmft.
  """

  @css_class {:or, [nil, :string, {:fun, [:map], :string}]}

  @sort {:or,
         [
           :string,
           {:list,
            {:tuple,
             [
               :atom,
               {:one_of,
                [
                  :asc,
                  :desc,
                  :asc_nils_first,
                  :asc_nils_last,
                  :desc_nils_first,
                  :desc_nils_last
                ]}
             ]}},
           {:list, :atom},
           {:list, :string},
           nil
         ]}

  @doc """
  Extra CSS classes. Will be appended to base classes. If a function, it will be passed the component assigns.
  """
  def css_class, do: @css_class

  @doc """
  Inheritable types will inherit from parent DSL if not defined, falling back to the Ash resource DSL where applicable.
  """
  def inheritable(type), do: {:or, [type, {:one_of, [:inherit]}]}

  @doc """
  A validated Ash sort input. Supports string or keyword list syntax.
  """
  def sort, do: @sort
end
