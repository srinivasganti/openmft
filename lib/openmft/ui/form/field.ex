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
      option_label: [
        default: :name,
        doc:
          "The attribute on the destination resource to use as the display label for relationship selects.",
        type: :atom
      ],
      options: [
        doc: "Static options list for select fields, e.g. [{\"Active\", :active}].",
        type: {:list, :any}
      ],
      path: [
        default: [],
        doc: "Append to the root path (nested paths are appended).",
        type: {:list, :atom}
      ],
      relationship: [
        doc: "The belongs_to relationship name for relationship selects.",
        type: :atom
      ],
      type: [
        default: :default,
        doc: "The type of the value in the form.",
        type: {:one_of, [:default, :long_text, :select, :short_text]}
      ]
    ]
end
