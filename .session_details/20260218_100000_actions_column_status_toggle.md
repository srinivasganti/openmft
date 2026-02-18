# Session: 2026-02-18 10:00 - Icon-based Actions Column with Status Toggle

## Summary
Replaced text-based action buttons (View, Edit, Delete) with an icon-based Actions column matching the target product screenshot (ss-cust-t01.png). Added an enable/disable toggle that controls company status, and made the delete button conditionally disabled — only enabled after a record is disabled first.

## Changes Made

### Modified Files
| File | Description |
|------|-------------|
| `lib/openmft_web/live/company_live/index.html.heex` | Replaced text buttons with icon action buttons: eye (View), pencil (Edit), check-circle/x-circle toggle (Enable/Disable), trash (Delete). Delete disabled when active via `disabled` attr + `btn-disabled opacity-30` classes. Tooltips on each icon. |
| `lib/openmft_web/live/company_live/index.ex` | Added `handle_event("toggle-status", ...)` that toggles between `:active` and `:inactive`. Updated delete handler with server-side guard — returns error flash if company is still active. |
| `test/openmft_web/live/company_live_test.exs` | Replaced single "deletes a company" test with three tests: "cannot delete an active company" (checks disabled attr), "deletes a company after disabling it" (toggle then delete), "toggles company status" (verifies icon changes on toggle cycle). |

## Technical Details

### Status Toggle
- Uses `Ash.Changeset.for_update(:update, %{status: new_status})` to toggle between `:active` and `:inactive`
- Green `hero-check-circle-solid` with `text-success` class when active
- Gray `hero-x-circle` with `text-base-content/30` when inactive
- Tooltip changes: "Disable" when active, "Enable" when inactive

### Delete Protection (two layers)
1. **Client-side**: `disabled` HTML attribute + `btn-disabled opacity-30` classes prevent clicking when active
2. **Server-side**: `handle_event("delete", ...)` checks `company.status == :active` and returns error flash instead of destroying

### Icon Choices (Heroicons)
- View: `hero-eye`
- Edit: `hero-pencil-square`
- Active toggle: `hero-check-circle-solid` (filled green)
- Inactive toggle: `hero-x-circle` (outline gray)
- Delete: `hero-trash` (red when enabled, grayed when disabled)

## Status
- All 79 tests pass
- Committed as `a8c164a` and pushed to master
