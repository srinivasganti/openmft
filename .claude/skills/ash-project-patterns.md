# Ash + Phoenix Project Patterns

## When to Use
When starting or retrofitting an Ash + Phoenix project with compile-time validated, declarative UI configuration patterns.

## Incremental Adoption Strategy

Adopt these patterns in layers. Each layer builds on the previous one but is useful on its own.

### Layer 1: Entity Macro (Week 1)

**Goal:** Eliminate Spark entity boilerplate.

1. Create `lib/<app>/dsl/entity.ex` with the entity macro
2. Create `lib/<app>/dsl/type.ex` with custom types (`css_class()`, `inheritable()`)
3. Convert existing entity modules to use the macro

**Immediate win:** Every new entity module is ~20 lines instead of ~50.

### Layer 2: Compile-Time Validation (Week 2)

**Goal:** Catch configuration errors before runtime.

1. Create `lib/<app>/dsl/verifiers.ex` base module
2. Start with uniqueness verifiers (they're the simplest)
3. Add completeness verifiers (cross-reference Ash resources)
4. Add validity verifiers (ensure referenced fields exist)

**Immediate win:** Configuration errors surface at `mix compile`, not in production.

### Layer 3: Transformer Pipeline (Week 3)

**Goal:** Eliminate repetitive configuration through smart defaults.

1. Create `lib/<app>/dsl/transformers.ex` base module with shared helpers
2. Implement the clear-and-rebuild pattern for your main entity types
3. Add three-tier default inheritance (section → type → instance)
4. Add `:inherit` sentinel for pulling descriptions from Ash resources

**Immediate win:** Users configure only what differs from convention.

### Layer 4: Theme System (Week 4+)

**Goal:** Swappable, verified component styling.

1. Define the base class contract
2. Create at least one preset (BEM for development, Tailwind/DaisyUI for production)
3. Wire compile-time lookup maps in LiveView
4. Implement `class/2,3` resolution

**Immediate win:** Themes are swappable at compile time with zero runtime cost.

## Ash-Specific Conventions

### Resource Organization

```
lib/<app>/
  resources/
    user.ex              # Ash.Resource
    post.ex              # Ash.Resource
  ui/
    dsl.ex               # Your DSL extension
    dsl/
      entity.ex
      type.ex
      transformers.ex
      verifiers.ex
    form/
      action.ex          # Form entities
      field.ex
    data_table/
      action.ex          # Table entities
      column.ex
    theme.ex
    info.ex
```

### DSL Usage in Resources

```elixir
defmodule MyApp.Resources.Post do
  use Ash.Resource,
    extensions: [MyApp.Dsl],
    domain: MyApp.Domain

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false, public?: true
    attribute :body, :string, allow_nil?: false, public?: true
  end

  actions do
    defaults [:read, :destroy]
    create :create do
      accept [:title, :body]
    end
    update :update do
      accept [:title, :body]
    end
  end

  # Your DSL extension
  form do
    action_type [:create, :update] do
      field :title
      field :body, type: :long_text
    end
  end

  data_table do
    action_type :read do
      column :title
      column :body, display: false
    end
  end
end
```

### Cross-Referencing Ash Resources

Always access resource info through `Ash.Resource.Info`:

```elixir
# In transformers/verifiers:
resource = Transformer.get_persisted(dsl, :resource)

# Get actions
Ash.Resource.Info.actions(resource)
Ash.Resource.Info.action(resource, :create)

# Get fields
Ash.Resource.Info.attributes(resource)
Ash.Resource.Info.public_attributes(resource)
Ash.Resource.Info.field(resource, :title)
Ash.Resource.Info.fields(resource, [:attributes, :aggregates, :calculations])

# Get relationships
Ash.Resource.Info.relationships(resource)

# Check capabilities
Ash.Resource.Info.sortable?(resource, :title)
```

### Testing Strategy

1. **Define realistic test resources** in `test/support/`:
   ```elixir
   defmodule MyApp.Test.PostResource do
     use Ash.Resource, extensions: [MyApp.Dsl], ...
     # Full resource with DSL configuration
   end
   ```

2. **Compile test resources** in `test_helper.exs`

3. **Test the full pipeline** — verifiers, transformers, and info access:
   ```elixir
   test "form actions are correctly merged" do
     form = MyApp.Info.form_for(MyApp.Test.PostResource, :create)
     assert form.label == "Create"
     assert length(form.fields) == 2
   end
   ```

4. **Test verifier failures** using inline module definitions:
   ```elixir
   test "rejects missing fields" do
     assert_raise Spark.Error.DslError, ~r/missing/, fn ->
       capture_io(:stderr, fn ->
         defmodule BadPost do
           use Ash.Resource, extensions: [MyApp.Dsl], ...
           # Config that should fail verification
         end
       end)
     end
   end
   ```

## Common Pitfalls

1. **Don't skip `after?/1`** — Transformers that access Ash resource info must run after Ash's own transformers
2. **Don't mix transformer and verifier concerns** — Transformers normalize data, verifiers check it
3. **Don't forget early returns** — If a section is empty, return `{:ok, dsl}` immediately
4. **Don't use runtime checks for compile-time problems** — If you can verify it at compile time, do so
5. **Don't fight Spark** — Use `Transformer.get_entities/2`, `Transformer.add_entity/4`, etc. Don't manipulate the DSL state directly

## Ash Usage Rules Integration

If using the `usage_rules` package, your project can automatically sync Ash's official rules:

```elixir
# In mix.exs
{:usage_rules, "~> 0.1", only: :dev, runtime: false}
```

```sh
mix usage_rules.sync
```

This generates/updates `AGENTS.md` or `CLAUDE.md` with rules from all deps that provide `usage-rules.md` files.
