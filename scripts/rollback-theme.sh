#!/usr/bin/env bash
# Restore the TacticalRMM frontend from a backup created by apply-theme.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
STATE_FILE="${THEME_DIR}/.state/last-backup"

TRMM_DIST_PATH="${TRMM_DIST_PATH:-/var/www/rmm/dist}"
BACKUP_PATH="${BACKUP_PATH:-}"
LIST_ONLY="${LIST_ONLY:-false}"
SKIP_NGINX_RELOAD="${SKIP_NGINX_RELOAD:-false}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Restaure le frontend TacticalRMM depuis une sauvegarde dist.bak.* créée par apply-theme.sh.

Options:
  --list              Lister les sauvegardes disponibles
  --backup PATH       Restaurer une sauvegarde précise
  --latest            Restaurer la dernière sauvegarde (défaut)
  -h, --help          Afficher cette aide

Variables d'environnement:
  TRMM_DIST_PATH      Chemin du frontend (défaut: /var/www/rmm/dist)
  BACKUP_PATH         Chemin de la sauvegarde à restaurer
  LIST_ONLY=true      Équivalent de --list
  SKIP_NGINX_RELOAD   Ne pas recharger nginx

Exemples:
  sudo ./scripts/rollback-theme.sh
  sudo ./scripts/rollback-theme.sh --list
  sudo BACKUP_PATH=/var/www/rmm/dist.bak.1717180800 ./scripts/rollback-theme.sh
EOF
}

log() {
  echo "[dracula-rollback] $*"
}

die() {
  echo "[dracula-rollback] ERROR: $*" >&2
  exit 1
}

list_backups() {
  local parent backup
  parent="$(dirname "${TRMM_DIST_PATH}")"
  local found=false

  log "Sauvegardes disponibles dans ${parent}:"
  while IFS= read -r backup; do
    found=true
    local marker=""
    if [[ -f "${STATE_FILE}" && "$(cat "${STATE_FILE}")" == "${backup}" ]]; then
      marker=" (dernière sauvegarde apply-theme)"
    fi
    echo "  ${backup}${marker}"
  done < <(find "${parent}" -maxdepth 1 -type d -name "$(basename "${TRMM_DIST_PATH}").bak.*" | sort -r)

  if [[ "${found}" == "false" ]]; then
    log "Aucune sauvegarde dist.bak.* trouvée."
    log "Alternative: relancer ./update.sh TacticalRMM pour restaurer le frontend officiel."
  fi
}

resolve_backup() {
  if [[ -n "${BACKUP_PATH}" ]]; then
    echo "${BACKUP_PATH}"
    return
  fi

  if [[ -f "${STATE_FILE}" ]]; then
    cat "${STATE_FILE}"
    return
  fi

  local parent latest
  parent="$(dirname "${TRMM_DIST_PATH}")"
  latest="$(find "${parent}" -maxdepth 1 -type d -name "$(basename "${TRMM_DIST_PATH}").bak.*" | sort -r | head -1)"
  echo "${latest}"
}

reload_nginx() {
  if [[ "${SKIP_NGINX_RELOAD}" == "true" ]]; then
    log "Rechargement nginx ignoré (SKIP_NGINX_RELOAD=true)"
    return
  fi

  if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet nginx 2>/dev/null; then
    log "Rechargement de nginx"
    systemctl reload nginx
  fi
}

restore_backup() {
  local backup="$1"

  [[ -n "${backup}" ]] || die "Aucune sauvegarde trouvée. Utilisez --list ou relancez ./update.sh TacticalRMM."
  [[ -d "${backup}" ]] || die "Sauvegarde introuvable: ${backup}"

  if [[ ! -w "$(dirname "${TRMM_DIST_PATH}")" ]] && [[ "$(id -u)" -ne 0 ]]; then
    die "Permissions insuffisantes. Exécutez avec sudo."
  fi

  local failed_backup="${TRMM_DIST_PATH}.failed.$(date +%s)"
  if [[ -d "${TRMM_DIST_PATH}" ]]; then
    log "Mise de côté du frontend actuel → ${failed_backup}"
    mv "${TRMM_DIST_PATH}" "${failed_backup}"
  fi

  log "Restauration de ${backup} → ${TRMM_DIST_PATH}"
  cp -a "${backup}/." "${TRMM_DIST_PATH}/"
  chown -R www-data:www-data "${TRMM_DIST_PATH}" 2>/dev/null || true

  reload_nginx
  log "Rollback terminé. Frontend officiel restauré depuis ${backup}"
  log "Pensez à vider le cache navigateur (Ctrl+Shift+R)."
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --list)
        LIST_ONLY=true
        shift
        ;;
      --backup)
        [[ $# -ge 2 ]] || die "Option --backup requiert un chemin"
        BACKUP_PATH="$2"
        shift 2
        ;;
      --latest)
        BACKUP_PATH=""
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Option inconnue: $1 (utilisez --help)"
        ;;
    esac
  done

  if [[ "${LIST_ONLY}" == "true" ]]; then
    list_backups
    exit 0
  fi

  restore_backup "$(resolve_backup)"
}

main "$@"
