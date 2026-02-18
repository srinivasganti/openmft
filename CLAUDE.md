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
| `Openmft.Ui.Info` | Introspection API (`form_for/2`, `data_table_for/2`) |
| `Openmft.Dsl.Entity` | Entity macro (derives struct, docs, Access from schema) |
| `Openmft.Dsl.Type` | Custom Spark types (`css_class`, `inheritable`) |
| `Openmft.Dsl.Transformers` | Shared transformer base + helpers |
| `Openmft.Dsl.Verifiers` | Shared verifier base |

### Conventions

1. **Schema is the single source of truth** — Derive structs, docs, types from schema definitions
2. **Fail at compile time** — Verifiers catch config errors before runtime
3. **Layered defaults** — Section → ActionType → Action override hierarchy
4. **Cross-reference Ash** — Validate DSL config against actual resource fields/actions
5. **Clear-and-rebuild** — Transformers expand multi-name entities, merge defaults, add back
6. **Pipeline separation** — Transformers normalize, verifiers validate, persisters optimize

### File Organization

```
lib/openmft/
  partners.ex                           # Ash Domain
  partners/
    company.ex                          # Company resource (has_many accounts)
    account.ex                          # Account resource (belongs_to company, has_many connections)
    connection.ex                       # Connection resource (belongs_to account)
  ui.ex                                 # Main Spark.Dsl entry point
  ui/
    info.ex                             # Introspection API
    dsl.ex                              # Extension registration
    dsl/
      transformers/
        merge_form_actions.ex           # Form clear-and-rebuild transformer
        merge_data_table_actions.ex     # DataTable clear-and-rebuild transformer
      verifiers/
        form/
          no_duplicate_actions.ex       # Uniqueness check
          no_duplicate_fields.ex        # Uniqueness with recursive group traversal
          all_fields_in_action.ex       # Cross-references Ash resource accepted attrs/args
        data_table/
          no_duplicate_actions.ex       # Uniqueness check
      persisters/
        data_table.ex                   # Pre-computes action-by-name map for O(1) lookup
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
```

### Testing Patterns

- **ETS-backed inline resources** for compile-time DSL tests (no DB needed)
- **`capture_io(:stderr, ...)`** to test that verifiers raise compile-time errors
- Test file: `test/openmft/ui_test.exs`
