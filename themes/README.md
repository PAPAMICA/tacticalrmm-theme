# TacticalRMM Theme Pack

Multi-theme pack with **dark + light** variants per theme.

## Structure

```
themes/
├── manifest.json
├── index.sass
├── shared/
│   ├── design-tokens.sass
│   ├── layout.sass        # Dashboard shell (splitter panels, sidebar, tree)
│   └── components.sass    # Components + per-theme overrides
├── dracula/
├── classic/
├── cyber/
├── swiss/
└── terminal/
```

## How switching works

1. **UI Theme** (User Preferences) → sets `body.theme-{name}` via `ui_theme` in DB
2. **Dark mode toggle** (header) → sets `body.body--dark` or `body.body--light` via Quasar

Each theme defines CSS variables under both `.body--dark` and `.body--light`, plus structural overrides in `components.sass`.

## Dashboard layout

Based on the live TRMM DOM (`home.html`):

- `q-page.dracula-dashboard` — page shell with optional background pattern
- `.dracula-nav` — FileBar navigation
- `q-splitter` panels — client sidebar + main content as floating cards
- `.q-list` / `.q-tree` — sidebar navigation styling
- `.dracula-subtabs` — server/workstation tabs

Each theme customizes padding, borders, shadows, and panel appearance differently.

## Theme IDs

| ID | Label |
|----|-------|
| `dracula` | Dracula |
| `classic` | Classic (TacticalRMM) |
| `cyber` | Cyber Dashboard |
| `swiss` | Swiss Enterprise |
| `terminal` | Terminal SRE |

Removed themes (`nothing`, `vision`, `neo`, `material`) fall back to `dracula`.
