# TacticalRMM — Multi-Theme Pack

UI theme pack for the [TacticalRMM](https://github.com/amidaware/tacticalrmm) frontend: full redesign, **5 themes** with **dark + light** variants, instant switching in User Preferences.

**Tested TacticalRMM version:** `WEB_VERSION=0.101.59` (TRMM v1.4.0)

## Available themes

| Theme | Dark | Light | Description |
|-------|------|-------|-------------|
| **Dracula** | Neon purple `#BD93F9` | Alucard `#644AC8` | [Official Dracula palette](https://draculatheme.com) |
| **Classic** | Quasar blue `#1976D2` | White/gray | Original TacticalRMM look |
| **Nothing Phone** | Black + red `#FF0022` | Minimal white | Nothing OS aesthetic |
| **Material Design** | MD3 dark `#D0BCFF` | MD3 light `#6750A4` | Material You, rounded corners |
| **Terminal** | Green phosphor `#39FF14` | CRT amber `#0A6E0A` | Monospace, console style |

### Dark + Light mode

Each theme has **two variants**:

- **UI Theme** (Preferences) → theme choice (`dracula`, `nothing`, etc.)
- **Moon/sun toggle** (header) → switches dark/light **for the active theme**

## UI redesign

| Area | Changes |
|------|---------|
| **Design system** | Shared tokens, `--theme-*` variables, Quasar components |
| **Header** | Theme-aware gradient, version badge |
| **Navigation (FileBar)** | Floating pill bar |
| **Login** | Glassmorphism card, dynamic logo, redesigned SSO |
| **Dashboard** | Modernized tabs, splitters, client tree |
| **Theme selector** | 5 themes × dark/light in User Preferences |
| **Tables** | Rounded borders, uppercase headers, row hover, improved sticky |
| **Modals** | Card header (no q-bar), deep shadows, themed borders |
| **Forms** | Filled inputs with focus ring, buttons with shadow |
| **Global components** | Menus, chips, tooltips, notifications, scrollbars |

## Dracula preview (default theme)

| Element | Dark | Light (Alucard) |
|---------|------|-----------------|
| Primary | `#BD93F9` | `#644AC8` |
| Background | `#282A36` | `#FFFBEB` |
| Accent | `#FF79C6` | `#A3144D` |

## Server requirements

- TacticalRMM installed (root or sudo access)
- **Node.js 18+** and **npm**
- **Git**
- ~500 MB free disk space for the build

```bash
# Check Node.js
node --version   # >= 18
npm --version
```

## Installation

### 1. Clone this repo on the server

```bash
sudo git clone https://github.com/PAPAMICA/tacticalrmm-theme.git /opt/tacticalrmm-theme
cd /opt/tacticalrmm-theme
sudo chmod +x scripts/*.sh
```

### 2. Apply backend patches (required for theme selector)

```bash
sudo ./scripts/apply-backend-patches.sh
```

Adds the `ui_theme` database field and exposes it via the API (`/core/dashinfo/`, `/accounts/users/ui/`).

The script automatically uses the TacticalRMM virtualenv (`/rmm/api/env/bin/python`).

```bash
# If detection fails, specify the venv manually:
sudo TRMM_VENV=/rmm/api/env ./scripts/apply-backend-patches.sh
```

### 3. Apply the frontend theme

```bash
sudo ./scripts/apply-theme.sh
```

The script:
1. Detects `WEB_VERSION` from `/rmm/api/tacticalrmm/tacticalrmm/settings.py`
2. Clones `tacticalrmm-web` at the matching tag (`v0.101.59`)
3. Applies patches and copies the `themes/` folder
4. Runs `quasar build`
5. Deploys to `/var/www/rmm/dist/` (preserves `env-config.js`)
6. Reloads nginx

### 4. Change theme in the UI

**Settings → Preferences → User Interface → UI Theme**

Then use the **dark mode toggle** in the header for the light or dark variant.

The choice is **saved per user** and applied instantly without a rebuild.

### 5. Hard refresh browser

After deployment, clear the cache or use `Ctrl+Shift+R` to see the new theme.

## Reapply after TacticalRMM update

Each `./update.sh` overwrites the official frontend. Reapply the theme afterward:

```bash
# Manual
sudo /opt/tacticalrmm-theme/scripts/post-update.sh

# Or directly
sudo /opt/tacticalrmm-theme/scripts/apply-theme.sh
```

### Automatic hook (optional)

Add to the end of your TacticalRMM `update.sh` script:

```bash
if [ -x /opt/tacticalrmm-theme/scripts/post-update.sh ]; then
  /opt/tacticalrmm-theme/scripts/post-update.sh
fi
```

`post-update.sh` only rebuilds if `WEB_VERSION` has changed since the last application.

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TRMM_WEB_VERSION` | auto | Force a version (e.g. `0.101.59`) |
| `TRMM_SETTINGS` | `/rmm/api/tacticalrmm/tacticalrmm/settings.py` | Django settings path |
| `TRMM_DIST_PATH` | `/var/www/rmm/dist` | Frontend destination |
| `TRMM_BUILD_DIR` | `/tmp/tacticalrmm-web-dracula-build` | Temporary build directory |
| `TRMM_WEB_REPO` | amidaware repo | Frontend repo URL |
| `TRMM_VENV` | auto (`/rmm/api/env`) | Django Python virtualenv path |
| `SKIP_NGINX_RELOAD` | `false` | Do not reload nginx |
| `DRY_RUN` | `false` | Build without deploying |
| `FORCE` | `false` | Force rebuild in post-update.sh |

Example:

```bash
sudo TRMM_WEB_VERSION=0.101.59 ./scripts/apply-theme.sh
```

## Rollback if something goes wrong

Yes. **`apply-theme.sh` automatically backs up** the existing frontend before deployment:

```
/var/www/rmm/dist  →  /var/www/rmm/dist.bak.<timestamp>
```

### Restore previous frontend (recommended)

```bash
# Restore the latest backup
sudo /opt/tacticalrmm-theme/scripts/rollback-theme.sh

# List all available backups
sudo /opt/tacticalrmm-theme/scripts/rollback-theme.sh --list

# Restore a specific backup
sudo /opt/tacticalrmm-theme/scripts/rollback-theme.sh --backup /var/www/rmm/dist.bak.1717180800
```

The script restores the backed-up content to `/var/www/rmm/dist/` and reloads nginx.

### Restore official TacticalRMM frontend

If no backup is available (or to start fresh):

```bash
cd /rmm
sudo ./update.sh
```

This re-downloads and reinstalls the official frontend from amidaware.

## Recommended user preferences

In **Settings → User Preferences**, these values align best with Dracula:

| Preference | Recommended value |
|------------|-------------------|
| Dark mode | Enabled |
| Loading bar color | `purple` |
| Dash info color | `info` |
| Dash positive color | `positive` |
| Dash negative color | `negative` |
| Dash warning color | `warning` |

Docs: [User Interface Preferences](https://docs.tacticalrmm.com/functions/user_ui/)

## Repository structure

```
tacticalrmm-theme/
├── themes/                    # Multi-theme pack (see themes/README.md)
│   ├── manifest.json
│   ├── index.sass
│   ├── shared/
│   ├── dracula/
│   ├── classic/
│   ├── nothing/
│   ├── material/
│   └── terminal/
├── patches/                   # 14 frontend patches
├── patches-backend/           # Django patches + ui_theme migration
├── frontend-src/              # Utility sources (reference)
├── assets/favicon.ico
└── scripts/
```

## Modified files (upstream)

| Patch | File | Redesign |
|-------|------|----------|
| 001 | `quasar.variables.sass` | Palette + Quasar border-radius |
| 002 | `app.sass` | Design system + Inter + themes |
| 003 | `App.vue` | Tables, highlights, CSS var links |
| 004 | `LoginView.vue` | Full login page |
| 005 | `MainLayout.vue` | Header gradient + version badge |
| 006 | `FileBar.vue` | Pill navigation |
| 007 | `DialogWrapper.vue` | Modern modals |
| 008 | `SubTableTabs.vue` | Agent panel tabs |
| 009 | `DashboardView.vue` | Servers/workstations tabs |
| 010 | `UserPreferences.vue` | **UI Theme selector** |
| 011 | `store/index.js` | Apply theme on load |
| 012 | `quasar.config.js` | Theme boot file |
| 013 | `utils/theme.js` | Theme switching logic |
| 014 | `boot/theme.js` | Default theme on startup |
| — | `themes/` | Copied from this repo during build |
| — | `public/favicon.ico` | Dracula favicon |

### Backend (patches-backend/)

| File | Change |
|------|--------|
| `accounts/models.py` | `ui_theme` field |
| `accounts/serializers.py` | Exposed in `UserUISerializer` |
| `core/views.py` | Returned by `/core/dashinfo/` |
| `migrations/0041_user_ui_theme.py` | Django migration |

## Limitations

- **MeshCentral** (remote control): separate UI, not themed
- **White labeling**: no native TacticalRMM support — this repo is a workaround
- **Versions**: patches target `v0.101.59`; a different `WEB_VERSION` may require patch updates
- **Updates**: the theme must be reapplied after each `./update.sh`

## Troubleshooting

### Backend migration — `ModuleNotFoundError: No module named 'django'`

TacticalRMM uses the virtualenv `/rmm/api/env`, not `venv`. Update the script and rerun:

```bash
cd /opt/tacticalrmm-theme && sudo git pull
sudo ./scripts/apply-backend-patches.sh
```

Or manually:

```bash
cd /rmm/api/tacticalrmm
/rmm/api/env/bin/python manage.py migrate accounts --noinput
sudo systemctl restart rmm rmm-daphne rmmcelery rmmcelerybeat
```

### Blank page — `Unexpected token '<'` in env-config.js

The Quasar build **does not include** `env-config.js`. This file is created by TacticalRMM during installation (`update.sh`) and contains the API URL:

```js
window._env_ = {PROD_URL: "https://api.yourdomain.com"}
```

Without this file, nginx returns `index.html` instead → blank page.

**Immediate fix** (on the server):

```bash
# Option 1: repair script
sudo /opt/tacticalrmm-theme/scripts/fix-env-config.sh

# Option 2: copy from backup
sudo cp /var/www/rmm/dist.bak.*/env-config.js /var/www/rmm/dist/env-config.js

# Option 3: regenerate manually
API=$(cd /rmm/api/tacticalrmm && python3 manage.py get_config api)
echo "window._env_ = {PROD_URL: \"https://${API}\"}" | sudo tee /var/www/rmm/dist/env-config.js
sudo chown www-data:www-data /var/www/rmm/dist/env-config.js
```

Then hard refresh the browser (`Ctrl+Shift+R`).

Recent versions of `apply-theme.sh` automatically preserve `env-config.js` during deployment.

### A patch fails to apply

```bash
# Check server WEB_VERSION
grep WEB_VERSION /rmm/api/tacticalrmm/tacticalrmm/settings.py

# Compare with this repo's SUPPORTED_WEB_VERSION
cat SUPPORTED_WEB_VERSION
```

If versions differ, open an issue or update the patches for the new version.

### npm build fails

```bash
node --version   # must be >= 18
cd /tmp/tacticalrmm-web-dracula-build && npm ci && npx quasar build
```

### Test without deploying

```bash
sudo DRY_RUN=true ./scripts/apply-theme.sh
# Build runs but /var/www/rmm/dist is not modified
```

## Credits

- [Dracula Theme](https://draculatheme.com) — MIT palette
- [TacticalRMM](https://github.com/amidaware/tacticalrmm) — amidaware
- [tacticalrmm-web](https://github.com/amidaware/tacticalrmm-web) — Quasar frontend

## License

MIT — see [LICENSE.md](LICENSE.md)
