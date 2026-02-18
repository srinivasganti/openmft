defmodule Openmft.Ui.Form.Field do
  @moduledoc """
  The configuration of a form field.
  """

  use Openmft.Dsl.Entity,
    name: :field,
    args: [:name],
    describe: "Declare non-default behavior for a specific form field.",
    schema: [
      autofocus: [
        default: false,
        doc: "Autofocus the field.",
        type: :boolean
      ],
      class: [
        doc: "Customize class.",
        type: Openmft.Dsl.Type.css_class()
      ],
      description: [
        doc: "Override the default extracted description.",
        type: :string
      ],
      label: [
        doc: "The label of the field (defaults to capitalized name).",
        type: :string
      ],
      name: [
        doc: "The name of the field to be modified.",
        required: true,
        type: :atom
      ],
      path: [
        default: [],
        doc: "Append to the root path (nested paths are appended).",
        type: {:list, :atom}
      ],
      type: [
        default: :default,
        doc: "The type of the value in the form.",
        type: {:one_of, [:default, :long_text, :select, :short_text]}
      ]
    ]
end
