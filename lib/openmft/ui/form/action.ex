defmodule Openmft.Ui.Form.Action do
  @moduledoc """
  A form configuration for an Ash resource action.
  """

  use Openmft.Dsl.Entity,
    name: :action,
    args: [:name],
    describe: "Configure the appearance of forms for specific action(s).",
    entities: [
      fields: [Openmft.Ui.Form.Field, Openmft.Ui.Form.FieldGroup]
    ],
    schema: [
      class: [
        doc: "Customize form classes.",
        type: Openmft.Dsl.Type.css_class()
      ],
      description: [
        doc: "The description for this form (defaults to action's description).",
        type: :string
      ],
      label: [
        doc: "The label for this form (defaults to capitalized name).",
        type: :string
      ],
      name: [
        doc: "The action name(s) for this form.",
        required: true,
        type: {:wrap_list, :atom}
      ]
    ]
end
