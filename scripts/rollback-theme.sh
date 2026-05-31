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

Restore the TacticalRMM frontend from a dist.bak.* backup created by apply-theme.sh.

Options:
  --list              List available backups
  --backup PATH       Restore a specific backup
  --latest            Restore the latest backup (default)
  -h, --help          Show this help

Environment variables:
  TRMM_DIST_PATH      Frontend path (default: /var/www/rmm/dist)
  BACKUP_PATH         Backup path to restore
  LIST_ONLY=true      Same as --list
  SKIP_NGINX_RELOAD   Do not reload nginx

Examples:
  sudo ./scripts/rollback-theme.sh
  sudo ./scripts/rollback-theme.sh --list
  sudo BACKUP_PATH=/var/www/rmm/dist.bak.1717180800 ./scripts/rollback-theme.sh
EOF
}

log() {
  echo "[trmm-theme-rollback] $*"
}

die() {
  echo "[trmm-theme-rollback] ERROR: $*" >&2
  exit 1
}

list_backups() {
  local parent backup
  parent="$(dirname "${TRMM_DIST_PATH}")"
  local found=false

  log "Available backups in ${parent}:"
  while IFS= read -r backup; do
    found=true
    local marker=""
    if [[ -f "${STATE_FILE}" && "$(cat "${STATE_FILE}")" == "${backup}" ]]; then
      marker=" (latest apply-theme backup)"
    fi
    echo "  ${backup}${marker}"
  done < <(find "${parent}" -maxdepth 1 -type d -name "$(basename "${TRMM_DIST_PATH}").bak.*" | sort -r)

  if [[ "${found}" == "false" ]]; then
    log "No dist.bak.* backups found."
    log "Alternative: run TacticalRMM ./update.sh to restore the official frontend."
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
    log "Skipping nginx reload (SKIP_NGINX_RELOAD=true)"
    return
  fi

  if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet nginx 2>/dev/null; then
    log "Reloading nginx"
    systemctl reload nginx
  fi
}

restore_backup() {
  local backup="$1"

  [[ -n "${backup}" ]] || die "No backup found. Use --list or run TacticalRMM ./update.sh."
  [[ -d "${backup}" ]] || die "Backup not found: ${backup}"

  if [[ ! -w "$(dirname "${TRMM_DIST_PATH}")" ]] && [[ "$(id -u)" -ne 0 ]]; then
    die "Insufficient permissions. Run with sudo."
  fi

  local failed_backup="${TRMM_DIST_PATH}.failed.$(date +%s)"
  if [[ -d "${TRMM_DIST_PATH}" ]]; then
    log "Moving current frontend aside → ${failed_backup}"
    mv "${TRMM_DIST_PATH}" "${failed_backup}"
  fi

  log "Restoring ${backup} → ${TRMM_DIST_PATH}"
  cp -a "${backup}/." "${TRMM_DIST_PATH}/"
  chown -R www-data:www-data "${TRMM_DIST_PATH}" 2>/dev/null || true

  reload_nginx
  log "Rollback complete. Frontend restored from ${backup}"
  log "Clear your browser cache (Ctrl+Shift+R)."
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --list)
        LIST_ONLY=true
        shift
        ;;
      --backup)
        [[ $# -ge 2 ]] || die "--backup requires a path"
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
        die "Unknown option: $1 (use --help)"
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
