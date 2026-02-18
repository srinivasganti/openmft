defmodule Openmft.Ui.DataTable.Column do
  @moduledoc """
  The configuration of a data table column.
  """

  use Openmft.Dsl.Entity,
    name: :column,
    args: [:name],
    describe: "Declare non-default behavior for a specific data table column.",
    schema: [
      cell_class: [
        doc: "Customize cell class.",
        type: Openmft.Dsl.Type.css_class()
      ],
      description: [
        doc: "Description of column.",
        type: Openmft.Dsl.Type.inheritable(:string)
      ],
      header_class: [
        doc: "Customize header class.",
        type: Openmft.Dsl.Type.css_class()
      ],
      label: [
        doc: "The label of the column (defaults to capitalized name).",
        type: :string
      ],
      name: [
        doc: "The name of the column.",
        required: true,
        type: :atom
      ],
      sortable?: [
        default: true,
        doc: "Enable sorting for this column.",
        type: :boolean
      ],
      source: [
        doc: "Source path for data (defaults to name).",
        type: {:list, :atom}
      ],
      type: [
        default: :default,
        doc: "The type of the column.",
        type: {:one_of, [:default]}
      ]
    ],
    transform: {__MODULE__, :__set_defaults__, []}

  alias Openmft.Dsl.Transformers

  @doc false
  def __set_defaults__(column) do
    {:ok,
     column
     |> Map.update!(:source, fn
       nil -> List.wrap(column.name)
       source -> source
     end)
     |> Map.update!(:label, fn
       nil -> Transformers.default_label(column.name)
       label -> label
     end)}
  end
end
