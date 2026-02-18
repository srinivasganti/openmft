# Create a Theme System

## When to Use
When you need consistent, swappable styling for UI components with compile-time guarantees that all required styles are defined.

## Architecture Overview

```
Theme Contract (required class names)
  ↓
Theme Presets (BEM, DaisyUI, custom)
  ↓
ApplyTheme Transformer (merge parent → child)
  ↓
ApplyPrefix Transformer (namespace classes)
  ↓
AllBaseClassesImplemented Verifier (completeness check)
  ↓
Compile-time lookup maps (@base_class, @base_class_for)
  ↓
Runtime class/3 resolution (theme base + DSL override)
```

## Steps

### 1. Define the Base Class Entity

```elixir
defmodule MyApp.Theme.BaseClass do
  use MyApp.Dsl.Entity,
    args: [:name, :value],
    name: :base_class,
    identifier: :name,           # Store as map keyed by name
    schema: [
      __identifier__: [private?: true],
      name: [doc: "Component name", required: true, type: :atom],
      prefixed: [type: :string, private?: true],   # Set by transformer
      value: [doc: "CSS class value", required: true, type: :string]
    ]

  @doc "All class names that themes must implement."
  def default_base_class_names do
    ~w[
      component_a
        component_a__element_1
        component_a__element_2
      component_b
        component_b__element_1
    ]a
  end
end
```

### 2. Create the Theme DSL Module

```elixir
defmodule MyApp.Theme do
  use Spark.Dsl,
    default_extensions: [extensions: [MyApp.Theme.Dsl]],
    opt_schema: [
      theme: [
        type: {:spark, MyApp.Theme},   # Allows inheriting from parent theme
        doc: "Parent theme to inherit from."
      ]
    ]

  @impl true
  def handle_opts(opts) do
    if parent = opts[:theme] do
      [persist: {:parent_theme, parent}]
    else
      []
    end
  end
end
```

### 3. Create the Theme Extension

```elixir
defmodule MyApp.Theme.Dsl do
  use Spark.Dsl.Extension,
    sections: [
      %Spark.Dsl.Section{
        name: :theme,
        describe: "Define theme base classes.",
        entities: [MyApp.Theme.BaseClass.__entity__()],
        schema: [
          prefix: [doc: "Namespace prefix for all classes.", type: :string]
        ]
      }
    ],
    transformers: [
      MyApp.Theme.Dsl.Transformers.ApplyTheme,
      MyApp.Theme.Dsl.Transformers.ApplyPrefix
    ],
    verifiers: [
      MyApp.Theme.Dsl.Verifiers.AllBaseClassesImplemented
    ]
end
```

### 4. Create the ApplyTheme Transformer

Merges parent theme classes, with child overrides taking precedence:

```elixir
defmodule MyApp.Theme.Dsl.Transformers.ApplyTheme do
  use Spark.Dsl.Transformer

  alias MyApp.Theme.BaseClass
  alias Spark.Dsl.Transformer

  @impl true
  def transform(dsl) do
    parent = Transformer.get_persisted(dsl, :parent_theme)

    dsl =
      if parent do
        # Add parent classes first
        parent_classes = Spark.Dsl.Extension.get_entities(parent, [:theme])
        Enum.reduce(parent_classes, dsl, fn class, dsl ->
          Transformer.add_entity(dsl, [:theme], class)
        end)
      else
        dsl
      end

    # Child classes override parent (identifier-based replacement)
    {:ok, dsl}
  end
end
```

### 5. Create the ApplyPrefix Transformer

Runs after ApplyTheme to namespace all classes:

```elixir
defmodule MyApp.Theme.Dsl.Transformers.ApplyPrefix do
  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer

  @impl true
  def after?(MyApp.Theme.Dsl.Transformers.ApplyTheme), do: true
  def after?(_), do: false

  @impl true
  def transform(dsl) do
    prefix = Transformer.get_option(dsl, [:theme], :prefix, nil)

    dsl =
      for class <- Transformer.get_entities(dsl, [:theme]), reduce: dsl do
        dsl ->
          prefixed = if prefix, do: "#{prefix}-#{class.value}", else: class.value
          updated = %{class | prefixed: prefixed}
          Transformer.replace_entity(dsl, [:theme], updated)
      end

    {:ok, dsl}
  end
end
```

### 6. Create the Completeness Verifier

```elixir
defmodule MyApp.Theme.Dsl.Verifiers.AllBaseClassesImplemented do
  use Spark.Dsl.Verifier

  alias MyApp.Theme.BaseClass
  alias Spark.Error.DslError

  @impl true
  def verify(dsl) do
    module = Spark.Dsl.Verifier.get_persisted(dsl, :module, nil)
    required = MapSet.new(BaseClass.default_base_class_names())
    implemented = dsl |> Spark.Dsl.Verifier.get_entities([:theme]) |> MapSet.new(& &1.name)

    missing = MapSet.difference(required, implemented)

    if MapSet.size(missing) > 0 do
      raise DslError.exception(
        module: module,
        path: [:theme],
        message: "missing base classes: #{inspect(MapSet.to_list(missing))}"
      )
    end

    :ok
  end
end
```

### 7. Create Theme Presets

**BEM-style preset (programmatic):**
```elixir
defmodule MyApp.Theme.BEM do
  use MyApp.Theme

  theme do
    for name <- MyApp.Theme.BaseClass.default_base_class_names() do
      value = name |> Atom.to_string() |> String.replace(~r/(?<!_)_(?!_)/, "-")
      base_class name, value
    end
  end
end
```

**Custom preset (hand-crafted):**
```elixir
defmodule MyApp.Theme.Tailwind do
  use MyApp.Theme

  theme do
    base_class :component_a, "bg-white shadow rounded-lg p-4"
    base_class :component_a__element_1, "text-lg font-bold"
    # ... all required classes
  end
end
```

**Child theme (inherits + overrides):**
```elixir
defmodule MyApp.Theme.Custom do
  use MyApp.Theme, theme: MyApp.Theme.Tailwind

  theme do
    # Only override what differs
    base_class :component_a, "bg-gray-50 shadow-md rounded-xl p-6"
  end
end
```

### 8. Build Compile-Time Lookup Maps in LiveView

```elixir
# In your LiveView module's handle_before_compile:
theme_entities = Spark.Dsl.Extension.get_entities(theme_module, [:theme])

# Direct name lookup
@base_class Map.new(theme_entities, fn e -> {e.name, e.prefixed} end)

# Entity-field lookup (auto-discover class fields from entity structs)
@base_class_for build_entity_class_map(entities, theme_entities)

def base_class(name), do: Map.fetch!(@base_class, name)
def base_class_for(entity, field), do: Map.get(@base_class_for, {entity.__struct__, field})
```

### 9. Runtime Class Resolution

```elixir
def class(base_class_name, override) do
  base = base_class(base_class_name)
  apply_class(base, override)
end

defp apply_class(base, nil), do: base
defp apply_class(base, extra) when is_binary(extra), do: "#{base} #{extra}"
defp apply_class(base, func) when is_function(func, 1), do: apply_class(base, func.(assigns))
defp apply_class(base, list) when is_list(list), do: Enum.reduce(list, base, &apply_class(&2, &1))
```

## Naming Convention

Use BEM-inspired double-underscore nesting for class names:
```
component
  component__element
  component__element__sub_element
```
