# OpenMFT

## Project Overview

OpenMFT is a Managed File Transfer system built with Phoenix 1.8, Ash 3.0, and AshPostgres 2.0. It includes a compile-time validated, declarative UI configuration system built on Spark DSL.

## Usage Rules

- Use generators first (`mix help` to list available tasks), then modify
- Pass `--yes` to generator tasks
- Run `mix precommit` before finalizing changes
- Run `mix test` to verify all tests pass

## Architecture

### Ash Domain

- `Openmft.Partners` — Domain containing Company → Account → Connection resources
- Resources use AshPostgres with `Openmft.Repo`

### DSL Pipeline

```
Entity Definitions → Transformers → Verifiers → Persisters → Runtime
```

1. **Entities** define the schema (what users write in DSL blocks)
2. **Transformers** normalize, merge, and expand entity data at compile time
3. **Verifiers** validate the fully-transformed DSL state, raising `DslError` on violations
4. **Persisters** pre-compute runtime lookup structures (maps, indexes)

### Key Modules

| Module | Purpose |
|--------|---------|
| `Openmft.Ui` | Main entry point (`use Spark.Dsl`), validates resource |
| `Openmft.Ui.Dsl` | Extension — registers `:form` and `:data_table` sections |
| `Openmft.Ui.Info` | Introspection API (`form_for/2`, `data_table_for/2`), both O(1) persisted |
| `Openmft.Dsl.Entity` | Entity macro (derives struct, docs, Access from schema) |
| `Openmft.Dsl.Type` | Custom Spark types (`css_class`, `inheritable`) |
| `Openmft.Dsl.Transformers` | Shared transformer base + helpers |
| `Openmft.Dsl.Verifiers` | Shared verifier base |
| `OpenmftWeb.UiComponents` | DSL-to-HTML bridge (`ui_data_table/1`, `ui_form/1`) |

### UI Page Modules

Each Ash resource gets a `Page` module that declares its UI via DSL:

```elixir
defmodule Openmft.Partners.Company.Page do
  use Openmft.Ui, resource: Openmft.Partners.Company

  form do
    action [:create, :update] do  # multi-name expansion
      field :name, autofocus: true
      field :description
      field :status
    end
  end

  data_table do
    action_type :read do
      exclude([:id])
      column(:name)
      column(:description)
      column(:status)
    end
  end
end
```

### LiveView Pattern

LiveViews reference a `@ui` page module and use `UiComponents` to render:

```elixir
@ui Company.Page

# In template:
<.ui_data_table ui={@ui} action={:read} rows={@companies} />
<.ui_form ui={@ui} action={@form_action} form={@form} />
```

- Use `AshPhoenix.Form.for_create/3` and `for_update/3` to build forms
- Use `handle_params` + `apply_action` pattern for `:index`/`:new`/`:edit` live actions
- Do NOT manually assign `:live_action` in `mount` — the router sets it

### Conventions

1. **Schema is the single source of truth** — Derive structs, docs, types from schema definitions
2. **Fail at compile time** — Verifiers catch config errors before runtime
3. **Layered defaults** — Section → ActionType → Action override hierarchy
4. **Cross-reference Ash** — Validate DSL config against actual resource fields/actions
5. **Clear-and-rebuild** — Transformers expand multi-name entities, merge defaults, add back
6. **Pipeline separation** — Transformers normalize, verifiers validate, persisters optimize
7. **DSL drives rendering** — `UiComponents` read config via `Info` module, never hardcode UI structure
8. **One Page module per resource** — Lives at `resource/page.ex` (e.g. `partners/company/page.ex`)

### File Organization

```
lib/openmft/
  partners.ex                           # Ash Domain
  partners/
    company.ex                          # Company resource (has_many accounts)
    company/
      page.ex                           # Company UI config (form + data_table DSL)
    account.ex                          # Account resource (belongs_to company, has_many connections)
    account/
      page.ex                           # Account UI config (form + data_table DSL)
    connection.ex                       # Connection resource (belongs_to account)
    connection/
      page.ex                           # Connection UI config (form + data_table DSL)
  ui.ex                                 # Main Spark.Dsl entry point
  ui/
    info.ex                             # Introspection API (O(1) persisted lookups)
    dsl.ex                              # Extension registration
    dsl/
      transformers/
        merge_form_actions.ex           # Form clear-and-rebuild transformer
        merge_data_table_actions.ex     # DataTable clear-and-rebuild transformer
      verifiers/
        form/
          no_duplicate_actions.ex       # Uniqueness check
          no_duplicate_fields.ex        # Uniqueness with recursive group traversal
          no_duplicate_field_labels.ex  # Label uniqueness within path context
          all_fields_in_action.ex       # Cross-references Ash resource accepted attrs/args
          all_accepted_included.ex      # All accepted attrs have form fields
          all_arguments_included.ex     # All action arguments have form fields
          exactly_one_autofocus.ex      # Semantic: one autofocus per form
        data_table/
          no_duplicate_actions.ex       # Uniqueness check
          no_duplicate_column_labels.ex # Label uniqueness
          all_columns_valid.ex          # Columns exist as public fields
          all_public_included.ex        # All public fields defined or excluded
          default_sorts_valid.ex        # Sort syntax and column references
          default_displays_valid.ex     # Display lists existing columns
      persisters/
        data_table.ex                   # Pre-computes action-by-name map for O(1) lookup
        form.ex                         # Pre-computes action-by-name map for O(1) lookup
    form/
      field.ex                          # Field entity
      field_group.ex                    # FieldGroup entity (recursive)
      action.ex                         # Form Action entity (multi-name)
      action_type.ex                    # Form ActionType entity
    data_table/
      column.ex                         # Column entity (with entity-level transform)
      action.ex                         # DataTable Action entity
      action_type.ex                    # DataTable ActionType entity
  dsl/
    entity.ex                           # Entity macro (single source of truth)
    type.ex                             # Custom Spark types
    transformers.ex                     # Shared transformer base + helpers
    verifiers.ex                        # Shared verifier base

lib/openmft_web/
  components/
    core_components.ex                  # Phoenix core UI components (daisyUI)
    ui_components.ex                    # DSL-driven components (ui_data_table, ui_form)
    layouts.ex                          # App layout, theme toggle
  live/
    company_live/
      index.ex                          # Company CRUD LiveView
      index.html.heex                   # Template using ui_data_table + ui_form
    account_live/
      index.ex                          # Account CRUD LiveView
      index.html.heex                   # Template using ui_data_table + ui_form
    connection_live/
      index.ex                          # Connection CRUD LiveView
      index.html.heex                   # Template using ui_data_table + ui_form
```

### Testing Patterns

- **ETS-backed inline resources** for compile-time DSL tests (no DB needed)
- **`capture_io(:stderr, ...)`** to test that verifiers raise compile-time errors
- **LiveView tests** use `ConnCase` + `Phoenix.LiveViewTest` with Postgres sandbox
- Flash messages render in layout, not LiveView — test data effects instead
- DSL tests: `test/openmft/ui_test.exs`
- LiveView tests: `test/openmft_web/live/{company,account,connection}_live_test.exs`
