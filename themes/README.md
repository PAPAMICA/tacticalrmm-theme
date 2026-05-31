# TacticalRMM Theme Pack

Multi-theme pack with **dark + light** variants per theme.

## Structure

```
themes/
├── manifest.json          # Registry of all themes
├── index.sass             # Entry point (imported by app.sass)
├── shared/
│   ├── design-tokens.sass # Radius, shadows (non-color)
│   └── components.sass    # Structural UI using --theme-* vars
├── dracula/
├── classic/
├── nothing/               # Nothing OS — monochrome industrial
├── cyber/                 # Cyber Dashboard — NOC/SOC
├── vision/                # Apple Vision Pro — frosted glass
├── swiss/                 # Swiss Enterprise — banking precision
├── terminal/              # Terminal SRE — engineer dashboard
└── neo/                   # Neo Minimal SaaS — Linear-inspired
```

## How switching works

1. **UI Theme** (User Preferences) → sets `body.theme-{name}` via `ui_theme` in DB
2. **Dark mode toggle** (header) → sets `body.body--dark` or `body.body--light` via Quasar

Each theme defines CSS variables under both `.body--dark` and `.body--light`.

## Adding a new theme

1. Create `themes/mytheme/dark.sass` and `light.sass`
2. Create `themes/mytheme/index.sass` importing both
3. Add `@import "mytheme/index.sass"` to `themes/index.sass`
4. Register in `themes/manifest.json` and `frontend-src/utils/theme.js`
5. Add theme-specific overrides in `shared/components.sass`

## CSS variable reference

All themes must define:

- `--theme-bg`, `--theme-fg`, `--theme-muted`
- `--theme-surface`, `--theme-surface-elevated`, `--theme-border`
- `--theme-primary`, `--theme-secondary`, `--theme-accent`
- `--theme-positive`, `--theme-negative`, `--theme-warning`, `--theme-info`
- `--theme-link`, `--theme-link-hover`
- `--theme-header-bg`, `--theme-login-bg`, `--theme-login-card-bg`
- `--theme-nav-bg`, `--theme-table-header-bg`, `--theme-highlight`
- `--theme-font`, `--theme-font-mono`, `--theme-logo-gradient`
- `--theme-radius-sm` … `--theme-radius-xl` (optional per theme)
- `--theme-shadow-sm` … `--theme-shadow-lg` (optional per theme)
- `--theme-transition`, `--theme-glass-blur`, `--theme-accent-glow` (optional)
- `--q-primary` … `--q-dark-page` (Quasar compatibility)

## Theme IDs

| ID | Label |
|----|-------|
| `dracula` | Dracula |
| `classic` | Classic (TacticalRMM) |
| `nothing` | Nothing OS |
| `cyber` | Cyber Dashboard |
| `vision` | Apple Vision Pro |
| `swiss` | Swiss Enterprise |
| `terminal` | Terminal SRE |
| `neo` | Neo Minimal SaaS |

Legacy `material` and `alucard` values fall back to `dracula`.
