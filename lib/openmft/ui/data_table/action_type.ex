defmodule Openmft.Ui.DataTable.ActionType do
  @moduledoc """
  Default data table configuration for actions of a given type.
  """

  use Openmft.Dsl.Entity,
    name: :action_type,
    args: [:name],
    describe:
      "Configure the default data table appearance for actions of type(s). Will be ignored by actions configured explicitly.",
    entities: [columns: [Openmft.Ui.DataTable.Column]],
    schema: [
      class: [
        doc: "Additional data table classes.",
        type: Openmft.Dsl.Type.css_class()
      ],
      default_display: [
        doc: "The columns to display by default.",
        type: {:list, :atom}
      ],
      description: [
        doc: "The description for this data table.",
        type: Openmft.Dsl.Type.inheritable(:string)
      ],
      exclude: [
        default: [],
        doc: "The fields to exclude from columns.",
        type: {:list, :atom}
      ],
      name: [
        doc: "The action type(s) for this data table.",
        required: true,
        type: {:wrap_list, {:one_of, [:read]}}
      ]
    ],
    transform: {Openmft.Ui.DataTable.Action, :__set_defaults__, []}
end
