# Session: 2026-02-18 09:00 - Salesforce-like UX Overhaul

## Summary
Implemented four major UX features to bring the app closer to a Salesforce/Workday enterprise experience: sortable columns with search bar, left sidebar navigation, record detail pages with related lists, and human-readable date formatting.

## Changes Made

### Feature 1: Sortable Columns + Search Bar

#### New Files
| File | Purpose |
|------|---------|
| `lib/openmft_web/data_table_state.ex` | Helper module for sort/search state management with Ash.Query integration |
| `test/openmft_web/data_table_state_test.exs` | Unit tests for cycle_sort, sort_direction |

#### Modified Files
| File | Description |
|------|-------------|
| `lib/openmft/partners/company/page.ex` | Added `default_sort [{:name, :asc}]` to data table DSL |
| `lib/openmft_web/components/ui_components.ex` | Added sort indicators on clickable headers, search bar with debounce, new backward-compatible attrs (sort, search_term, on_search) |
| `lib/openmft_web/live/company_live/index.ex` | Added DataTableState integration, extracted `load_companies/1`, added sort-column/search/clear-search event handlers |
| `lib/openmft_web/live/company_live/index.html.heex` | Pass sort/search assigns to ui_data_table |
| `test/openmft_web/live/company_live_test.exs` | Added tests for sort asc/desc, search filter, clear search |

#### Technical Details
- `DataTableState.build_query/2` uses `Ash.Query.sort/2` and `Ash.Query.filter_input/2` with `%{or: [%{col => %{contains: term}}]}` for multi-column text search
- `cycle_sort/3` implements single-column sort cycling: none → asc → desc → none
- `searchable_columns/2` auto-detects string-typed Ash attributes from the resource
- All features opt-in via nil defaults — existing pages work unchanged

### Feature 2: Left Sidebar Navigation

#### Modified Files
| File | Description |
|------|-------------|
| `lib/openmft_web/components/layouts.ex` | Replaced top navbar with daisyUI drawer sidebar. Fixed left sidebar on desktop, hamburger menu on mobile. Partners section with icons, theme toggle in footer, content area widened to max-w-5xl |

### Feature 3: Record Detail Pages

#### New Files
| File | Purpose |
|------|---------|
| `lib/openmft_web/live/company_live/show.ex` | Company detail LiveView with related Accounts |
| `lib/openmft_web/live/company_live/show.html.heex` | Company detail template with details card + accounts table |
| `lib/openmft_web/live/account_live/show.ex` | Account detail LiveView with related Connections |
| `lib/openmft_web/live/account_live/show.html.heex` | Account detail template with details card + connections table |

#### Modified Files
| File | Description |
|------|-------------|
| `lib/openmft_web/router.ex` | Added `/companies/:id` and `/accounts/:id` show routes |
| `lib/openmft_web/components/core_components.ex` | Added `.badge` component for status display |
| `lib/openmft_web/live/company_live/index.html.heex` | Row click navigates to show page, added View/Edit action links |
| `lib/openmft_web/live/account_live/index.html.heex` | Same: View/Edit action links, navigate to show |
| `lib/openmft_web/live/connection_live/index.html.heex` | Updated row actions |

### Feature 4: Date Formatting

#### Modified Files
| File | Description |
|------|-------------|
| `lib/openmft_web/components/ui_components.ex` | Added `format_value/1` for DateTime/NaiveDateTime → "Feb 18, 2026 08:05 AM" |

## Status
- All 77 tests pass
- 4 commits made locally:
  - `7dff14d` feat: add sortable columns and search bar to data table
  - `9e2e222` feat: replace top navbar with Salesforce-style left sidebar
  - `ab200ed` feat: add record detail pages with related lists
  - `84d136c` feat: add human-readable date formatting in data tables
