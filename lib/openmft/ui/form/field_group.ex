defmodule Openmft.Ui.Form.FieldGroup do
  @moduledoc """
  A group of form fields.
  """

  use Openmft.Dsl.Entity,
    name: :field_group,
    args: [:label],
    describe: "Configure the appearance of form field groups.",
    recursive_as: :fields,
    entities: [fields: [Openmft.Ui.Form.Field]],
    schema: [
      class: [
        doc: "Customize class.",
        type: Openmft.Dsl.Type.css_class()
      ],
      label: [
        doc: "The label of this group (defaults to capitalized name).",
        type: :string
      ],
      path: [
        default: [],
        doc: "Append to the root path (nested paths are appended).",
        type: {:list, :atom}
      ]
    ]
end
