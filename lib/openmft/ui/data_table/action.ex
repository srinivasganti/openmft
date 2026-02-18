defmodule Openmft.Ui.DataTable.Action do
  @moduledoc """
  A data table configuration for specific action(s).
  """

  use Openmft.Dsl.Entity,
    name: :action,
    args: [:name],
    describe: "Configure the appearance of the data table for specific action(s).",
    entities: [columns: [Openmft.Ui.DataTable.Column]],
    schema: [
      class: [
        doc: "Customize data table classes.",
        type: Openmft.Dsl.Type.css_class()
      ],
      default_display: [
        doc: "The columns to display by default.",
        type: {:list, :atom}
      ],
      default_sort: [
        doc: "The default sort for this data table.",
        type: Openmft.Dsl.Type.sort()
      ],
      description: [
        doc: "The description for this data table.",
        type: Openmft.Dsl.Type.inheritable(:string)
      ],
      column_order: [
        doc: "The DSL-declared column order (set by transformer).",
        type: {:list, :atom},
        hide: [:docs]
      ],
      exclude: [
        default: [],
        doc: "The fields to exclude from columns.",
        type: {:list, :atom}
      ],
      label: [
        doc: "The label for this data table (defaults to capitalized name).",
        type: :string
      ],
      name: [
        doc: "The action name(s) for this data table.",
        required: true,
        type: {:wrap_list, :atom}
      ]
    ],
    transform: {__MODULE__, :__set_defaults__, []}

  @doc false
  def __set_defaults__(action) do
    {:ok,
     action
     |> Map.update!(:default_display, fn
       nil -> Enum.map(action.columns, & &1.name)
       display -> display
     end)}
  end
end
