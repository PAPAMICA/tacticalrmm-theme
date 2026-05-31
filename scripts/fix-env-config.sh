#!/usr/bin/env bash
# Restore env-config.js required by TacticalRMM frontend (fixes blank page).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TRMM_DIST_PATH="${TRMM_DIST_PATH:-/var/www/rmm/dist}"
TRMM_MANAGE_DIR="${TRMM_MANAGE_DIR:-/rmm/api/tacticalrmm}"
PROD_URL="${PROD_URL:-}"

log() {
  echo "[dracula-fix-env] $*"
}

die() {
  echo "[dracula-fix-env] ERROR: $*" >&2
  exit 1
}

main() {
  if [[ -f "${TRMM_DIST_PATH}/env-config.js" ]]; then
    log "env-config.js existe déjà dans ${TRMM_DIST_PATH}"
    cat "${TRMM_DIST_PATH}/env-config.js"
    exit 0
  fi

  local backup state_file="${THEME_DIR}/.state/last-backup"
  if [[ -f "${state_file}" ]]; then
    backup="$(cat "${state_file}")"
    if [[ -f "${backup}/env-config.js" ]]; then
      cp "${backup}/env-config.js" "${TRMM_DIST_PATH}/env-config.js"
      chown www-data:www-data "${TRMM_DIST_PATH}/env-config.js" 2>/dev/null || true
      log "env-config.js restauré depuis ${backup}"
      cat "${TRMM_DIST_PATH}/env-config.js"
      exit 0
    fi
  fi

  local latest_backup
  latest_backup="$(find "$(dirname "${TRMM_DIST_PATH}")" -maxdepth 1 -type d -name "$(basename "${TRMM_DIST_PATH}").bak.*" | sort -r | head -1)"
  if [[ -n "${latest_backup}" && -f "${latest_backup}/env-config.js" ]]; then
    cp "${latest_backup}/env-config.js" "${TRMM_DIST_PATH}/env-config.js"
    chown www-data:www-data "${TRMM_DIST_PATH}/env-config.js" 2>/dev/null || true
    log "env-config.js restauré depuis ${latest_backup}"
    cat "${TRMM_DIST_PATH}/env-config.js"
    exit 0
  fi

  local api=""
  if [[ -n "${PROD_URL}" ]]; then
    api="${PROD_URL#https://}"
    api="${api#http://}"
  elif [[ -d "${TRMM_MANAGE_DIR}" ]]; then
    api="$(cd "${TRMM_MANAGE_DIR}" && python3 manage.py get_config api 2>/dev/null || true)"
  fi

  [[ -n "${api}" ]] || die "Impossible de déterminer l'URL API. Exécutez: PROD_URL=https://api.votredomaine.com $0"

  echo "window._env_ = {PROD_URL: \"https://${api}\"}" | tee "${TRMM_DIST_PATH}/env-config.js"
  chown www-data:www-data "${TRMM_DIST_PATH}/env-config.js" 2>/dev/null || true
  log "env-config.js généré"
}

main "$@"
