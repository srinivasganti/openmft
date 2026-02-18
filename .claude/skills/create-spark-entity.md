# Create a Spark DSL Entity

## When to Use
When you need to define a new configurable unit in a Spark DSL — a form field, a column, an action config, a theme class, etc.

## Prerequisites
- An entity macro module exists (see `lib/pyro_maniac/dsl/entity.ex` for reference)
- The entity will be registered in a DSL extension section

## Steps

### 1. Create the Entity Module

Create `lib/<app>/<section>/<entity_name>.ex`:

```elixir
defmodule MyApp.Section.EntityName do
  @moduledoc """
  Brief description of what this entity configures.
  """

  use MyApp.Dsl.Entity,
    name: :entity_name,
    args: [:name],                    # positional args in DSL syntax
    describe: "What users see in docs.",
    # Optional: nested entities
    entities: [
      children: [MyApp.Section.ChildEntity]
    ],
    # Optional: for recursive nesting (e.g., field groups containing fields)
    # recursive_as: :children,
    # Optional: unique identifier field (for Map-based storage instead of List)
    # identifier: :name,
    schema: [
      name: [
        doc: "The name of this entity.",
        required: true,
        type: :atom
      ],
      label: [
        doc: "Display label (defaults to capitalized name).",
        type: :string
      ],
      class: [
        doc: "CSS classes for styling.",
        type: MyApp.Dsl.Type.css_class()
      ]
    ]
end
```

### 2. Key Options Reference

| Option | Purpose | Example |
|--------|---------|---------|
| `name` | DSL keyword | `:field`, `:action`, `:column` |
| `args` | Positional args | `[:name]`, `[:name, :value]` |
| `schema` | Field definitions | Spark.Options format |
| `entities` | Nested entities | `[fields: [Field, FieldGroup]]` |
| `identifier` | Unique key field | `:name` (stores as Map, not List) |
| `recursive_as` | Self-nesting key | `:fields` (for FieldGroup containing Fields) |
| `describe` | DSL docs | String description |

### 3. Register in DSL Extension

Add to the section's `entities` list in your DSL extension:

```elixir
%Spark.Dsl.Section{
  name: :my_section,
  entities: [
    MyApp.Section.EntityName.__entity__()
  ]
}
```

### 4. Multi-Name Pattern

To let users configure multiple items at once, make the name accept a list:

```elixir
name: [
  type: {:wrap_list, :atom},   # single atom or list of atoms
  required: true
]
```

Then expand in a transformer: `for name <- names, do: %{entity | name: name}`

### 5. Entity-Level Transform

For entities that need self-contained defaults (e.g., setting a label from the name):

```elixir
use MyApp.Dsl.Entity,
  name: :my_entity,
  transform: {__MODULE__, :__set_defaults__, []},
  schema: [...]

def __set_defaults__(entity) do
  {:ok, %{entity | label: entity.label || default_label(entity.name)}}
end
```

## Validation Checklist

- [ ] Schema defines all fields the struct needs
- [ ] Required fields have `required: true`
- [ ] Custom types used where appropriate (`css_class()`, `inheritable(:string)`)
- [ ] Entity registered in the DSL extension section
- [ ] `__entity__()` called when composing into parent entities
- [ ] Moduledoc present (the macro appends schema docs automatically)
