# Create a Spark DSL Transformer

## When to Use
When you need to normalize, merge, expand, or enrich DSL entity data at compile time — before verifiers run.

## Prerequisites
- A transformer base module exists (see `lib/pyro_maniac/dsl/transformers.ex`)
- The DSL extension has a `transformers` list to register in

## Steps

### 1. Create the Transformer Module

Place in `lib/<app>/dsl/transformers/<name>.ex`:

```elixir
defmodule MyApp.Dsl.Transformers.TransformerName do
  @moduledoc false

  use MyApp.Dsl.Transformers

  alias Spark.Dsl.Transformer

  # Run after Ash resource transformers to access resource info
  @ash_resource_transformers Ash.Resource.Dsl.transformers()

  @impl true
  def after?(module) when module in @ash_resource_transformers, do: true
  def after?(_), do: false

  @impl true
  def transform(dsl) do
    # Early return if section is empty
    if [] == Transformer.get_entities(dsl, [:my_section]) do
      {:ok, dsl}
    else
      {:ok, do_transform(dsl)}
    end
  end

  defp do_transform(dsl) do
    # Build context from DSL state
    context = %{
      module: Transformer.get_persisted(dsl, :module, nil),
      resource_actions: get_resource_actions(dsl),
      default_class: Transformer.get_option(dsl, [:my_section], :class, nil)
    }

    # ... transformation logic ...
    dsl
  end
end
```

### 2. The Clear-and-Rebuild Pattern

The most common transformer pattern — used when multi-name entities need expansion or defaults need merging:

```elixir
defp do_transform(dsl) do
  context = build_context(dsl)

  # Phase 1: Expand multi-name entities
  actions =
    for %Action{name: names} = action <- Transformer.get_entities(dsl, [:my_section]),
        name <- List.wrap(names) do
      %{action | name: name} |> merge_defaults(context)
    end

  # Phase 2: Collect type defaults (for generating missing actions)
  action_types =
    for %ActionType{name: names} = at <- Transformer.get_entities(dsl, [:my_section]),
        name <- List.wrap(names),
        into: %{} do
      {name, %{at | name: name}}
    end

  # Phase 3: Clear all originals
  dsl =
    Transformer.remove_entity(dsl, [:my_section], fn
      %Action{} -> true
      %ActionType{} -> true
      _ -> false
    end)

  # Phase 4: Generate defaults for missing actions
  default_actions = generate_defaults(context, actions, action_types)

  # Phase 5: Add all back
  Enum.reduce(actions ++ default_actions, dsl, fn action, dsl ->
    Transformer.add_entity(dsl, [:my_section], action, prepend: true)
  end)
end
```

### 3. Three-Tier Default Inheritance

Implement layered defaults: Section → ActionType → Action

```elixir
defp merge_defaults(%Action{} = action, context) do
  action
  |> Map.put(:label, action.label || default_label(action.name))
  |> Map.put(:class, action.class || context.default_class)
  |> Map.put(:description, resolve_description(action, context))
  |> Map.put(:fields, merge_fields(action.fields, context))
end
```

### 4. Description Inheritance with `:inherit` Sentinel

Allow `:inherit` to pull descriptions from the Ash resource:

```elixir
defp resolve_description(%{description: :inherit, name: name}, context) do
  context.resource_actions
  |> Map.get(name)
  |> Map.get(:description)
end

defp resolve_description(%{description: desc}, _context), do: desc
```

Use `inheritable(:string)` type in the entity schema to allow this.

### 5. Recursive Field Merging

For nested entities (field groups, steps), merge recursively with path accumulation:

```elixir
defp merge_fields(fields, context, root_path \\ []) do
  Enum.map(fields, fn
    %Field{} = field ->
      field
      |> Map.put(:path, maybe_append_path(root_path, field.path))
      |> Map.put(:label, field.label || default_label(field))

    %FieldGroup{} = group ->
      group_path = maybe_append_path(root_path, group.path)
      group
      |> Map.put(:path, group_path)
      |> Map.put(:label, group.label || default_label(group))
      |> Map.put(:fields, merge_fields(group.fields, context, group_path))
  end)
end
```

### 6. Register the Transformer

Add to the DSL extension in the correct order:

```elixir
use Spark.Dsl.Extension,
  transformers: [
    MyApp.Dsl.Transformers.TransformerName
    # Order matters — use after?/1 for explicit ordering
  ]
```

### 7. Ordering Between Custom Transformers

If transformer B depends on transformer A's output:

```elixir
# In transformer B:
@impl true
def after?(MyApp.Dsl.Transformers.TransformerA), do: true
def after?(_), do: false
```

## Key Conventions

- Return `{:ok, dsl}` on success (not bare `:ok` — that's for verifiers)
- Use `Transformer.get_entities/2` and `Transformer.get_option/4` to read DSL state
- Use `Transformer.add_entity/4`, `Transformer.remove_entity/3` to modify entities
- Use `Transformer.persist/3` to store computed data for runtime access
- Always run after Ash resource transformers when accessing resource info
- Early return with `{:ok, dsl}` if the section is empty
- Raise `DslError` for irrecoverable problems (missing required config)
- Build a context map upfront to avoid repeated DSL queries
