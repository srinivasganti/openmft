defmodule OpenmftWeb.DataTableState do
  @moduledoc """
  Shared helpers for sort and search state management in data tables.
  """

  alias Openmft.Ui.Info

  @doc """
  Initializes sort and search assigns from DSL config.

  Returns a keyword list with:
    - `:sort` - the current sort as an Ash-compatible keyword list
    - `:search_term` - the current search string (empty initially)
    - `:searchable_columns` - list of column names that are string-typed
  """
  @spec init(module(), atom(), Ash.Resource.t()) :: keyword()
  def init(ui_module, action, resource) do
    config = Info.data_table_for(ui_module, action)
    sort = parse_default_sort(config.default_sort, resource)
    searchable = searchable_columns(config, resource)

    [sort: sort, search_term: "", searchable_columns: searchable]
  end

  @doc """
  Cycles a column's sort direction: none -> asc -> desc -> none.
  Returns the updated sort keyword list (single-column sort).
  """
  @spec cycle_sort(keyword(), atom(), map()) :: keyword()
  def cycle_sort(current_sort, column_name, columns_map) do
    column = Map.get(columns_map, column_name)

    if column == nil or not column.sortable? do
      current_sort
    else
      case Keyword.get(current_sort, column_name) do
        nil -> [{column_name, :asc}]
        :asc -> [{column_name, :desc}]
        :desc -> []
      end
    end
  end

  @doc """
  Returns the sort direction for a given column, or nil if not sorted.
  """
  @spec sort_direction(keyword(), atom()) :: :asc | :desc | nil
  def sort_direction(sort, column_name) do
    Keyword.get(sort, column_name)
  end

  @doc """
  Builds an Ash.Query with the current sort and search applied.
  """
  @spec build_query(Ash.Resource.t(), keyword()) :: Ash.Query.t()
  def build_query(resource, opts) do
    sort = Keyword.get(opts, :sort, [])
    search_term = Keyword.get(opts, :search_term, "")
    searchable_columns = Keyword.get(opts, :searchable_columns, [])
    action = Keyword.get(opts, :action, :read)

    resource
    |> Ash.Query.for_read(action)
    |> maybe_sort(sort)
    |> maybe_search(search_term, searchable_columns)
  end

  defp parse_default_sort(nil, _resource), do: []

  defp parse_default_sort(default_sort, resource) do
    case Ash.Sort.parse_input(resource, default_sort) do
      {:ok, sort} -> sort
      {:error, _} -> []
    end
  end

  defp searchable_columns(config, resource) do
    string_attrs =
      resource
      |> Ash.Resource.Info.attributes()
      |> Enum.filter(&(&1.type == Ash.Type.String))
      |> MapSet.new(& &1.name)

    config.column_order
    |> Enum.filter(&MapSet.member?(string_attrs, &1))
  end

  defp maybe_sort(query, []), do: query
  defp maybe_sort(query, sort), do: Ash.Query.sort(query, sort)

  defp maybe_search(query, "", _columns), do: query
  defp maybe_search(query, _term, []), do: query

  defp maybe_search(query, term, columns) do
    or_clauses = Enum.map(columns, fn col -> %{col => %{contains: term}} end)
    Ash.Query.filter_input(query, %{or: or_clauses})
  end
end
