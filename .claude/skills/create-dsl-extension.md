# Create a Spark DSL Extension

## When to Use
When you need to add declarative configuration to an Ash resource or any Spark-powered module. This is the top-level orchestration pattern.

## Steps

### 1. Plan Your DSL Structure

Before writing code, define:
- **Sections** — Top-level DSL blocks (e.g., `:form`, `:data_table`)
- **Entities** — Configurable items within sections (e.g., `:action`, `:field`)
- **Entity hierarchy** — Parent/child relationships (action → field, field_group → field)
- **Section schema** — Section-level defaults (class, description, exclude)
- **Verifiers** — What needs compile-time validation
- **Transformers** — What needs normalization or merging

### 2. Create the Entity Macro (if you don't have one)

See the `create-spark-entity` skill for the full entity macro. Place in `lib/<app>/dsl/entity.ex`.

### 3. Create Custom Types (if needed)

Place in `lib/<app>/dsl/type.ex`:

```elixir
defmodule MyApp.Dsl.Type do
  # CSS class: nil, string, or function of assigns
  def css_class, do: {:or, [nil, :string, {:fun, [:map], :string}]}

  # Inheritable value (can be :inherit to pull from parent/resource)
  def inheritable(type), do: {:or, [type, {:one_of, [:inherit]}]}
end
```

### 4. Create Entity Modules

One module per entity type. See `create-spark-entity` skill for details.

### 5. Create the Transformer Base

Place in `lib/<app>/dsl/transformers.ex`:

```elixir
defmodule MyApp.Dsl.Transformers do
  @moduledoc false

  defmacro __using__(_env) do
    quote do
      use Spark.Dsl.Transformer
      import unquote(__MODULE__)
    end
  end

  # Add shared helper functions here
  def default_label(name) when is_atom(name),
    do: name |> Atom.to_string() |> String.split("_") |> Enum.map_join(" ", &String.capitalize/1)
end
```

### 6. Create the Verifier Base

Place in `lib/<app>/dsl/verifiers.ex`:

```elixir
defmodule MyApp.Dsl.Verifiers do
  @moduledoc false

  defmacro __using__(_env) do
    quote do
      use Spark.Dsl.Verifier
      import MyApp.Dsl.Transformers
      import unquote(__MODULE__)
      alias Spark.Dsl.Verifier
      alias Spark.Error.DslError
    end
  end
end
```

### 7. Create Transformers and Verifiers

See the `create-transformer` and `create-verifier` skills for details.

### 8. Create the Extension Module

This is the main registration point. Place in `lib/<app>/dsl.ex`:

```elixir
defmodule MyApp.Dsl do
  @moduledoc """
  Declarative UI configuration for Ash resources.
  """

  use Spark.Dsl.Extension,
    sections: [
      %Spark.Dsl.Section{
        name: :my_section,
        describe: "Configure the appearance of...",
        entities: [
          MyApp.Section.Action.__entity__(),
          MyApp.Section.ActionType.__entity__()
        ],
        schema: [
          class: [
            doc: "Default class for this section.",
            type: MyApp.Dsl.Type.css_class()
          ],
          description: [
            doc: "Default description.",
            type: MyApp.Dsl.Type.inheritable(:string)
          ],
          exclude: [
            default: [],
            doc: "Actions to exclude.",
            type: {:list, :atom}
          ]
        ]
      }
    ],
    transformers: [
      MyApp.Dsl.Transformers.MergeActions
    ],
    verifiers: [
      MyApp.Dsl.Verifiers.NoDuplicateActions,
      MyApp.Dsl.Verifiers.AllFieldsValid
    ],
    persisters: [
      MyApp.Dsl.Persisters.ActionsByName
    ]
end
```

### 9. Create the Main Module

The entry point that users `use` in their Ash resources:

```elixir
defmodule MyApp do
  use Spark.Dsl,
    default_extensions: [extensions: [MyApp.Dsl]],
    opt_schema: [
      resource: [
        type: {:behaviour, Ash.Resource},
        required: true,
        doc: "The Ash resource to configure."
      ]
    ]

  @impl true
  def init(opts) do
    if opts[:resource], do: {:ok, opts}, else: {:error, "resource is required"}
  end

  @impl true
  def handle_opts(opts) do
    [persist: {:resource, opts[:resource]}]
  end
end
```

### 10. Create an Info Module (Introspection API)

```elixir
defmodule MyApp.Info do
  def action_for(module, action_name) do
    module
    |> Spark.Dsl.Extension.get_entities([:my_section])
    |> Enum.find(&(&1.name == action_name))
  end

  # For persisted data (O(1) lookup):
  def action_for_fast(module, action_name) do
    module
    |> Spark.Dsl.Extension.get_persisted(:actions_by_name)
    |> Map.get(action_name)
  end
end
```

### 11. Add Formatter Support

In `.formatter.exs`, add DSL sections for import sorting:

```elixir
spark_locals_without_parens = [
  # entities
  action: 1,
  action_type: 1,
  field: 1,
  # schema keys
  class: 1,
  label: 1,
  description: 1
]

[
  import_deps: [:ash, :spark],
  locals_without_parens: spark_locals_without_parens,
  export: [locals_without_parens: spark_locals_without_parens]
]
```

## Pipeline Summary

```
User writes DSL → Entities parsed → Transformers normalize/merge
→ Verifiers validate → Persisters index → Runtime access via Info
```

## File Structure

```
lib/<app>/
  dsl.ex                    # Extension (registration point)
  dsl/
    entity.ex               # Entity macro
    type.ex                 # Custom types
    transformers.ex         # Transformer base + helpers
    transformers/
      merge_actions.ex
    verifiers.ex            # Verifier base
    verifiers/
      section/
        no_duplicates.ex
    persisters/
      actions_by_name.ex
  section/
    action.ex               # Entity modules
    field.ex
  info.ex                   # Introspection API
```
