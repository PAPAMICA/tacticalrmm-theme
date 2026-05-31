# TacticalRMM — Dracula Theme

Thème [Dracula](https://draculatheme.com) pour le frontend [TacticalRMM](https://github.com/amidaware/tacticalrmm).

Ce dépôt applique une palette Dracula complète au frontend Quasar (`tacticalrmm-web`) via des patches source, puis rebuild et déploie le résultat sur votre serveur.

**Version TacticalRMM testée :** `WEB_VERSION=0.101.59` (TRMM v1.4.0)

## Aperçu

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
├── palette/dracula.sass       # Tokens Dracula + variables Quasar CSS
├── patches/                   # Patches git pour tacticalrmm-web
├── assets/favicon.ico         # Favicon Dracula
├── scripts/
│   ├── apply-theme.sh         # Script principal
│   ├── post-update.sh         # Hook post-update
│   └── rollback-theme.sh      # Restauration depuis sauvegarde
└── SUPPORTED_WEB_VERSION      # Version WEB testée
```

## Fichiers modifiés (upstream)

- `src/css/quasar.variables.sass` — palette Quasar compile-time
- `src/css/app.sass` — import palette + scrollbars terminal
- `src/css/dracula.sass` — copié depuis `palette/` (runtime CSS vars)
- `src/App.vue` — tables, highlights, statuts agents
- `src/views/LoginView.vue` — gradient et titre login
- `src/layouts/MainLayout.vue` — header violet Dracula
- `public/favicon.ico` — favicon personnalisé

## Limitations

- **MeshCentral** (prise en main à distance) : UI séparée, non thématisée
- **White labeling** : pas de support natif TacticalRMM — ce dépôt est un contournement
- **Versions** : les patches ciblent `v0.101.59` ; une autre `WEB_VERSION` peut nécessiter une mise à jour des patches
- **Mises à jour** : le thème doit être réappliqué après chaque `./update.sh`

## Dépannage

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
