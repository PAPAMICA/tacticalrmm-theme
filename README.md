# TacticalRMM — Dracula Theme

Thème [Dracula](https://draculatheme.com) pour le frontend [TacticalRMM](https://github.com/amidaware/tacticalrmm).

Ce dépôt applique un **redesign UI complet** au frontend Quasar (`tacticalrmm-web`) : palette Dracula, typographie, composants, layout et pages clés — via des patches source, puis rebuild et déploiement sur votre serveur.

**Version TacticalRMM testée :** `WEB_VERSION=0.101.59` (TRMM v1.4.0)

## Redesign — ce qui change

| Zone | Changements |
|------|-------------|
| **Design system** | Tokens (radius, ombres, bordures), police Inter, variables CSS `--drac-*` |
| **Header** | Gradient violet, badge version, boutons arrondis |
| **Navigation (FileBar)** | Barre pill flottante avec hover violet |
| **Login** | Carte glassmorphism, logo, gradient animé, formulaire dark, SSO redesigné |
| **Dashboard** | Tabs modernisés, splitters stylisés, arbre clients avec hover |
| **Tables** | Bordures arrondies, headers uppercase, hover lignes, sticky amélioré |
| **Modales** | Header card (plus de q-bar), ombres profondes, bordures violettes |
| **Formulaires** | Inputs filled avec focus ring violet, boutons avec ombre |
| **Composants globaux** | Menus, chips, tooltips, notifications, scrollbars |

## Aperçu couleurs

| Élément | Couleur Dracula |
|---------|-----------------|
| Primary (boutons, header) | Purple `#BD93F9` |
| Secondary / Info | Cyan `#8BE9FD` |
| Accent | Pink `#FF79C6` |
| Background | `#282A36` |
| Surfaces | `#21222C` / `#44475A` |
| Succès | Green `#50FA7B` |
| Erreurs | Red `#FF5555` |
| Avertissements | Orange `#FFB86C` |

## Prérequis serveur

- TacticalRMM installé (accès root ou sudo)
- **Node.js 18+** et **npm**
- **Git**
- ~500 Mo d'espace disque libre pour le build

```bash
# Vérifier Node.js
node --version   # >= 18
npm --version
```

## Installation

### 1. Cloner ce dépôt sur le serveur

```bash
sudo git clone https://github.com/PAPAMICA/tacticalrmm-theme.git /opt/tacticalrmm-theme
cd /opt/tacticalrmm-theme
sudo chmod +x scripts/*.sh
```

### 2. Appliquer le thème

```bash
sudo ./scripts/apply-theme.sh
```

Le script :
1. Détecte `WEB_VERSION` depuis `/rmm/api/tacticalrmm/tacticalrmm/settings.py`
2. Clone `tacticalrmm-web` au tag correspondant (`v0.101.59`)
3. Applique les patches Dracula et copie la palette + favicon
4. Exécute `quasar build`
5. Déploie dans `/var/www/rmm/dist/`
6. Recharge nginx

### 3. Forcer un hard refresh navigateur

Après déploiement, videz le cache ou utilisez `Ctrl+Shift+R` pour voir le nouveau thème.

## Réapplication après mise à jour TacticalRMM

Chaque `./update.sh` écrase le frontend officiel. Relancez le thème ensuite :

```bash
# Manuel
sudo /opt/tacticalrmm-theme/scripts/post-update.sh

# Ou directement
sudo /opt/tacticalrmm-theme/scripts/apply-theme.sh
```

### Hook automatique (optionnel)

Ajoutez à la fin de votre script `update.sh` TacticalRMM :

```bash
if [ -x /opt/tacticalrmm-theme/scripts/post-update.sh ]; then
  /opt/tacticalrmm-theme/scripts/post-update.sh
fi
```

`post-update.sh` ne rebuild que si `WEB_VERSION` a changé depuis la dernière application.

## Variables d'environnement

| Variable | Défaut | Description |
|----------|--------|-------------|
| `TRMM_WEB_VERSION` | auto | Force une version (ex. `0.101.59`) |
| `TRMM_SETTINGS` | `/rmm/api/tacticalrmm/tacticalrmm/settings.py` | Chemin settings Django |
| `TRMM_DIST_PATH` | `/var/www/rmm/dist` | Destination du frontend |
| `TRMM_BUILD_DIR` | `/tmp/tacticalrmm-web-dracula-build` | Répertoire de build temporaire |
| `TRMM_WEB_REPO` | repo amidaware | URL du repo frontend |
| `SKIP_NGINX_RELOAD` | `false` | Ne pas recharger nginx |
| `DRY_RUN` | `false` | Build sans déploiement |
| `FORCE` | `false` | Force rebuild dans post-update.sh |

Exemple :

```bash
sudo TRMM_WEB_VERSION=0.101.59 ./scripts/apply-theme.sh
```

## Rollback en cas de problème

Oui. **`apply-theme.sh` sauvegarde automatiquement** le frontend existant avant déploiement :

```
/var/www/rmm/dist  →  /var/www/rmm/dist.bak.<timestamp>
```

### Restaurer le frontend précédent (recommandé)

```bash
# Restaurer la dernière sauvegarde
sudo /opt/tacticalrmm-theme/scripts/rollback-theme.sh

# Lister toutes les sauvegardes disponibles
sudo /opt/tacticalrmm-theme/scripts/rollback-theme.sh --list

# Restaurer une sauvegarde précise
sudo /opt/tacticalrmm-theme/scripts/rollback-theme.sh --backup /var/www/rmm/dist.bak.1717180800
```

Le script remet le contenu sauvegardé dans `/var/www/rmm/dist/` et recharge nginx.

### Restaurer le frontend officiel TacticalRMM

Si aucune sauvegarde n'est disponible (ou pour repartir proprement) :

```bash
cd /rmm
sudo ./update.sh
```

Cela retélécharge et réinstalle le frontend officiel depuis amidaware.

## Préférences utilisateur recommandées

Dans **Settings → User Preferences**, ces valeurs s'alignent le mieux avec Dracula :

| Préférence | Valeur recommandée |
|------------|-------------------|
| Dark mode | Activé |
| Loading bar color | `purple` |
| Dash info color | `info` |
| Dash positive color | `positive` |
| Dash negative color | `negative` |
| Dash warning color | `warning` |

Doc : [User Interface Preferences](https://docs.tacticalrmm.com/functions/user_ui/)

## Structure du dépôt

```
tacticalrmm-theme/
├── palette/
│   ├── dracula.sass           # Tokens couleurs + design
│   └── dracula-components.sass # Overrides Quasar globaux
├── patches/                   # 9 patches pour tacticalrmm-web
├── assets/favicon.ico
├── scripts/
│   ├── apply-theme.sh
│   ├── post-update.sh
│   ├── rollback-theme.sh
│   └── fix-env-config.sh
└── SUPPORTED_WEB_VERSION
```

## Fichiers modifiés (upstream)

| Patch | Fichier | Redesign |
|-------|---------|----------|
| 001 | `quasar.variables.sass` | Palette + border-radius Quasar |
| 002 | `app.sass` | Import design system + police Inter |
| 003 | `App.vue` | Tables, highlights, liens |
| 004 | `LoginView.vue` | Page login complète |
| 005 | `MainLayout.vue` | Header gradient + badge version |
| 006 | `FileBar.vue` | Navigation pill |
| 007 | `DialogWrapper.vue` | Modales modernes |
| 008 | `SubTableTabs.vue` | Tabs agent panel |
| 009 | `DashboardView.vue` | Tabs serveurs/workstations |
| — | `dracula.sass` / `dracula-components.sass` | Copiés depuis `palette/` |
| — | `public/favicon.ico` | Favicon Dracula |

## Limitations

- **MeshCentral** (prise en main à distance) : UI séparée, non thématisée
- **White labeling** : pas de support natif TacticalRMM — ce dépôt est un contournement
- **Versions** : les patches ciblent `v0.101.59` ; une autre `WEB_VERSION` peut nécessiter une mise à jour des patches
- **Mises à jour** : le thème doit être réappliqué après chaque `./update.sh`

## Dépannage

### Page blanche — `Unexpected token '<'` dans env-config.js

Le build Quasar **n'inclut pas** `env-config.js`. Ce fichier est créé par TacticalRMM à l'installation (`update.sh`) et contient l'URL de l'API :

```js
window._env_ = {PROD_URL: "https://api.votredomaine.com"}
```

Sans ce fichier, nginx renvoie `index.html` à la place → page blanche.

**Correctif immédiat** (sur le serveur) :

```bash
# Option 1 : script de réparation
sudo /opt/tacticalrmm-theme/scripts/fix-env-config.sh

# Option 2 : copier depuis la sauvegarde
sudo cp /var/www/rmm/dist.bak.*/env-config.js /var/www/rmm/dist/env-config.js

# Option 3 : régénérer manuellement
API=$(cd /rmm/api/tacticalrmm && python3 manage.py get_config api)
echo "window._env_ = {PROD_URL: \"https://${API}\"}" | sudo tee /var/www/rmm/dist/env-config.js
sudo chown www-data:www-data /var/www/rmm/dist/env-config.js
```

Puis hard refresh navigateur (`Ctrl+Shift+R`).

Les versions récentes de `apply-theme.sh` préservent automatiquement `env-config.js` lors du déploiement.

### Un patch ne s'applique pas

```bash
# Vérifier la WEB_VERSION du serveur
grep WEB_VERSION /rmm/api/tacticalrmm/tacticalrmm/settings.py

# Comparer avec SUPPORTED_WEB_VERSION de ce dépôt
cat SUPPORTED_WEB_VERSION
```

Si les versions diffèrent, ouvrez une issue ou mettez à jour les patches pour la nouvelle version.

### Build npm échoue

```bash
node --version   # doit être >= 18
cd /tmp/tacticalrmm-web-dracula-build && npm ci && npx quasar build
```

### Tester sans déployer

```bash
sudo DRY_RUN=true ./scripts/apply-theme.sh
# Le build est effectué mais /var/www/rmm/dist n'est pas modifié
```

## Crédits

- [Dracula Theme](https://draculatheme.com) — palette MIT
- [TacticalRMM](https://github.com/amidaware/tacticalrmm) — amidaware
- [tacticalrmm-web](https://github.com/amidaware/tacticalrmm-web) — frontend Quasar

## Licence

MIT — voir [LICENSE.md](LICENSE.md)
