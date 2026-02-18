defmodule Openmft.Ui.Dsl do
  @moduledoc """
  Declarative configuration of user interfaces for Ash resources.
  """

  use Spark.Dsl.Extension,
    sections: [
      %Spark.Dsl.Section{
        describe: "Configure the appearance of data tables.",
        entities: [
          Openmft.Ui.DataTable.Action.__entity__(),
          Openmft.Ui.DataTable.ActionType.__entity__()
        ],
        name: :data_table,
        schema: [
          class: [
            doc: "The default class for the data table.",
            type: Openmft.Dsl.Type.css_class()
          ],
          description: [
            doc: "The default description for data tables.",
            type: Openmft.Dsl.Type.inheritable(:string)
          ],
          exclude: [
            default: [],
            doc: "The actions to exclude from data tables.",
            type: {:list, :atom}
          ]
        ]
      },
      %Spark.Dsl.Section{
        describe: "Configure the appearance of forms.",
        entities: [
          Openmft.Ui.Form.Action.__entity__(),
          Openmft.Ui.Form.ActionType.__entity__()
        ],
        name: :form,
        schema: [
          class: [
            doc: "The default class for the form.",
            type: Openmft.Dsl.Type.css_class()
          ],
          description: [
            doc: "The default description for forms.",
            type: Openmft.Dsl.Type.inheritable(:string)
          ],
          exclude: [
            default: [],
            doc: "The actions to exclude from forms.",
            type: {:list, :atom}
          ]
        ]
      }
    ],
    transformers: [
      __MODULE__.Transformers.MergeDataTableActions,
      __MODULE__.Transformers.MergeFormActions
    ],
    verifiers: [
      __MODULE__.Verifiers.DataTable.NoDuplicateActions,
      __MODULE__.Verifiers.Form.AllFieldsInAction,
      __MODULE__.Verifiers.Form.NoDuplicateActions,
      __MODULE__.Verifiers.Form.NoDuplicateFields
    ],
    persisters: [
      __MODULE__.Persisters.DataTable
    ]
end
