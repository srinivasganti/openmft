# Session: 2026-02-18 00:22 - Relationship-Aware Forms

## Summary
Implemented automatic select dropdown rendering for enum fields (atom + `one_of` constraints) and relationship fields (`belongs_to` foreign keys). The transformer auto-detects both types at compile time so Page authors need no changes — `field :company_id, label: "Company"` auto-renders as a select dropdown.

## Changes Made

### Modified Files
| File | Description |
|------|-------------|
| `lib/openmft/ui/form/field.ex` | Added `options`, `relationship`, and `option_label` attributes to Field entity schema |
| `lib/openmft/ui/dsl/transformers/merge_form_actions.ex` | Added `detect_select_type/2` with `find_belongs_to_for_field/2` and `get_enum_options/2` helpers |
| `lib/openmft/ui/dsl.ex` | Registered `ValidSelectOptions` verifier |
| `lib/openmft/ui/dsl/persisters/form.ex` | Persists `:form_select_fields` map for runtime relationship field loading |
| `lib/openmft/ui/info.ex` | Added `relationship_select_fields/2` and `load_select_options/3` |
| `lib/openmft_web/components/ui_components.ex` | Added `options` attr to `ui_form`, select-specific `render_field/3` with merged options and `prompt="Select..."` |
| `lib/openmft_web/live/account_live/index.ex` | Load select options in mount, pass to template |
| `lib/openmft_web/live/account_live/index.html.heex` | Pass `options={@select_options}` to `ui_form` |
| `lib/openmft_web/live/connection_live/index.ex` | Load select options in mount, pass to template |
| `lib/openmft_web/live/connection_live/index.html.heex` | Pass `options={@select_options}` to `ui_form` |
| `test/openmft/ui_test.exs` | 6 new tests for auto-detection, persister, and verifier |
| `test/openmft_web/live/account_live_test.exs` | Verify company dropdown renders with prompt and options |
| `test/openmft_web/live/connection_live_test.exs` | Verify account dropdown renders with prompt and options |

### New Files
| File | Purpose |
|------|---------|
| `lib/openmft/ui/dsl/verifiers/form/valid_select_options.ex` | Validates select fields have proper options/relationship config (not both, not neither) |

## Technical Details

### Two Categories of Select Fields

1. **Enum selects** — Ash atom attributes with `one_of` constraints (e.g., `status`, `protocol`). Options are static and embedded in the Field struct at compile time as `[{"Active", :active}, ...]`.

2. **Relationship selects** — Fields matching a `belongs_to` source_attribute (e.g., `company_id`). The transformer sets `relationship: :company` on the Field. Options are loaded at runtime by the LiveView via `Info.load_select_options/3`.

### Pipeline Flow

- **Transformer** (`detect_select_type/2`): Auto-detects after path/label are set. Skips if user explicitly set `type:`. Checks: explicit options -> belongs_to match -> atom+one_of match.
- **Verifier** (`ValidSelectOptions`): Validates select fields post-transformation — must have options XOR relationship, relationship must exist, option_label must be public on destination.
- **Persister**: Additionally persists `:form_select_fields` — `%{action_name => %{field_name => %{relationship, option_label}}}`.
- **Info**: `load_select_options/3` reads destination resources via `Ash.read!` and builds `%{field_name => [{label, value}]}`.
- **UiComponents**: `render_field/3` for selects merges static `field.options` with runtime `options[field.name]`.

### Key Design Decision
Enum options are embedded at compile time (zero runtime cost), while relationship options are loaded at runtime since the data is dynamic. The `options` map attr on `ui_form` bridges both — static options come from the Field struct, dynamic options from LiveView assigns.

## Status
- 59 tests, 0 failures
- `mix precommit` passes clean
- `mix compile --warnings-as-errors` clean
- No Page module changes required — auto-detection is fully transparent
