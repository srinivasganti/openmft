defmodule Openmft.Ui.Form.ActionType do
  @moduledoc """
  Default form configuration for actions of a given type.
  """

  use Openmft.Dsl.Entity,
    name: :action_type,
    args: [:name],
    describe:
      "Configure default form appearance for actions of type(s). Will be ignored by actions configured explicitly.",
    entities: [
      fields: [Openmft.Ui.Form.Field, Openmft.Ui.Form.FieldGroup]
    ],
    schema: [
      class: [
        doc: "Customize form classes.",
        type: Openmft.Dsl.Type.css_class()
      ],
      name: [
        doc: "The action type(s) for this form.",
        required: true,
        type: {:wrap_list, {:one_of, [:create, :update]}}
      ]
    ]
end
