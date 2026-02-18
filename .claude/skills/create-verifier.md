# Create a Compile-Time Verifier

## When to Use
When you need to catch configuration errors at compile time — duplicate names, missing fields, invalid references, semantic constraints.

## Prerequisites
- A verifier base module exists (see `lib/pyro_maniac/dsl/verifiers.ex`)
- The DSL extension has a `verifiers` list to register in

## Steps

### 1. Identify the Verifier Category

| Category | Purpose | Example |
|----------|---------|---------|
| **Uniqueness** | No duplicate names/labels | `NoDuplicateFields`, `NoDuplicateActions` |
| **Completeness** | All resource items accounted for | `AllAcceptedIncluded`, `AllPublicIncluded` |
| **Validity** | References exist in resource | `AllColumnsValid`, `AllFieldsInAction` |
| **Semantic** | Business rules | `ExactlyOneAutofocus`, `DefaultSortsValid` |

### 2. Create the Verifier Module

Place in `lib/<app>/dsl/verifiers/<section>/<name>.ex`:

```elixir
defmodule MyApp.Dsl.Verifiers.Section.VerifierName do
  @moduledoc """
  Brief description of what this verifier checks.
  """

  use MyApp.Dsl.Verifiers

  @impl true
  def verify(dsl) do
    module = Verifier.get_persisted(dsl, :module, nil)

    # Get entities from the DSL
    for entity <- Verifier.get_entities(dsl, [:my_section]) do
      # Perform validation logic
      if some_violation?(entity) do
        raise DslError.exception(
          module: module,
          path: [:my_section, :entity_type, entity.name],
          message: "clear description of what went wrong"
        )
      end
    end

    :ok
  end
end
```

### 3. Common Verifier Patterns

**Uniqueness check:**
```elixir
def verify(dsl) do
  module = Verifier.get_persisted(dsl, :module, nil)

  entities = Verifier.get_entities(dsl, [:my_section])
  names = Enum.map(entities, & &1.name)
  duplicates = names -- Enum.uniq(names)

  for name <- Enum.uniq(duplicates) do
    raise DslError.exception(
      module: module,
      path: [:my_section],
      message: "duplicate entity name: #{inspect(name)}"
    )
  end

  :ok
end
```

**Completeness check (cross-reference Ash resource):**
```elixir
def verify(dsl) do
  module = Verifier.get_persisted(dsl, :module, nil)
  resource = Verifier.get_persisted(dsl, :resource)

  configured = dsl |> Verifier.get_entities([:my_section]) |> MapSet.new(& &1.name)
  required = resource |> Ash.Resource.Info.public_attributes() |> MapSet.new(& &1.name)

  missing = MapSet.difference(required, configured)

  if MapSet.size(missing) > 0 do
    raise DslError.exception(
      module: module,
      path: [:my_section],
      message: "missing configuration for: #{inspect(MapSet.to_list(missing))}"
    )
  end

  :ok
end
```

**Validity check (referenced items exist):**
```elixir
def verify(dsl) do
  module = Verifier.get_persisted(dsl, :module, nil)
  resource = Verifier.get_persisted(dsl, :resource)
  valid_fields = resource |> Ash.Resource.Info.fields([:attributes, :aggregates, :calculations]) |> MapSet.new(& &1.name)

  for entity <- Verifier.get_entities(dsl, [:my_section]),
      field <- entity.fields,
      field.name not in valid_fields do
    raise DslError.exception(
      module: module,
      path: [:my_section, :entity, entity.name],
      message: "field #{inspect(field.name)} does not exist in resource"
    )
  end

  :ok
end
```

### 4. Register the Verifier

Add to the DSL extension:

```elixir
use Spark.Dsl.Extension,
  verifiers: [
    MyApp.Dsl.Verifiers.Section.VerifierName
  ]
```

### 5. Test the Verifier

```elixir
test "rejects invalid configuration" do
  assert_raise Spark.Error.DslError, ~r/expected error message/, fn ->
    capture_io(:stderr, fn ->
      defmodule BadConfig do
        use Ash.Resource, ...
        # ... configuration that should trigger the verifier
      end
    end)
  end
end
```

## Key Conventions

- Always return `:ok` on success (not `{:ok, dsl}` — that's for transformers)
- Always include `module`, `path`, and `message` in `DslError`
- The `path` should be navigable — include the section, entity type, and entity name
- Use `Verifier.get_persisted/3` for module and resource access
- Use `Verifier.get_entities/2` to read DSL entities
- Cross-reference Ash resource info via `Ash.Resource.Info` functions
- Run after transformers have normalized the data — verifiers see the final state
