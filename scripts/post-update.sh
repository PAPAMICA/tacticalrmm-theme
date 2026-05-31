#!/usr/bin/env bash
# Reapply Dracula theme after TacticalRMM update when WEB_VERSION changes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
STATE_DIR="${THEME_DIR}/.state"
STATE_FILE="${STATE_DIR}/last-applied-version"

TRMM_SETTINGS="${TRMM_SETTINGS:-/rmm/api/tacticalrmm/tacticalrmm/settings.py}"
FORCE="${FORCE:-false}"

log() {
  echo "[dracula-post-update] $*"
}

get_current_web_version() {
  if [[ -n "${TRMM_WEB_VERSION:-}" ]]; then
    echo "${TRMM_WEB_VERSION}"
    return
  fi

  if [[ -f "${TRMM_SETTINGS}" ]]; then
    grep -E '^WEB_VERSION\s*=' "${TRMM_SETTINGS}" | head -1 | sed -E 's/.*"([^"]+)".*/\1/'
    return
  fi

  echo ""
}

main() {
  local current last_applied

  current="$(get_current_web_version)"
  if [[ -z "${current}" ]]; then
    log "WEB_VERSION introuvable — lancement de apply-theme.sh avec la version par défaut du thème"
    exec "${SCRIPT_DIR}/apply-theme.sh"
  fi

  last_applied=""
  if [[ -f "${STATE_FILE}" ]]; then
    last_applied="$(cat "${STATE_FILE}")"
  fi

  log "WEB_VERSION actuel: ${current}"
  log "Dernière application du thème: ${last_applied:-jamais}"

  if [[ "${FORCE}" == "true" || "${current}" != "${last_applied}" ]]; then
    if [[ "${current}" != "${last_applied}" ]]; then
      log "WEB_VERSION a changé — réapplication du thème Dracula"
    else
      log "FORCE=true — réapplication du thème Dracula"
    fi
    TRMM_WEB_VERSION="${current}" exec "${SCRIPT_DIR}/apply-theme.sh"
  else
    log "WEB_VERSION inchangé — aucune action requise"
  fi
}

main "$@"
