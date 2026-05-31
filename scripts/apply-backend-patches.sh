#!/usr/bin/env bash
# Apply backend patches for UI theme preference (Django).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TRMM_API_DIR="${TRMM_API_DIR:-/rmm/api/tacticalrmm}"
TRMM_VENV="${TRMM_VENV:-/rmm/api/tacticalrmm/venv}"
RESTART_SERVICES="${RESTART_SERVICES:-true}"

log() {
  echo "[dracula-backend] $*"
}

die() {
  echo "[dracula-backend] ERROR: $*" >&2
  exit 1
}

main() {
  [[ -d "${TRMM_API_DIR}" ]] || die "Répertoire API introuvable: ${TRMM_API_DIR}"

  local patch
  for patch in "${THEME_DIR}"/patches-backend/*.patch; do
    [[ -f "${patch}" ]] || continue
    log "Application de $(basename "${patch}")"
    git -C "${TRMM_API_DIR}" apply --check "${patch}" 2>/dev/null || {
      log "  (déjà appliqué ou conflit — tentative apply)"
    }
    git -C "${TRMM_API_DIR}" apply "${patch}" 2>/dev/null || log "  → ignoré (probablement déjà appliqué)"
  done

  local migration_src="${THEME_DIR}/patches-backend/accounts/migrations/0041_user_ui_theme.py"
  local migration_dst="${TRMM_API_DIR}/accounts/migrations/0041_user_ui_theme.py"
  if [[ -f "${migration_src}" && ! -f "${migration_dst}" ]]; then
    cp "${migration_src}" "${migration_dst}"
    log "Migration 0041_user_ui_theme.py installée"
  fi

  log "Exécution de la migration Django"
  if [[ -f "${TRMM_VENV}/bin/python" ]]; then
    (cd "${TRMM_API_DIR}" && "${TRMM_VENV}/bin/python" manage.py migrate accounts --noinput)
  else
    (cd "${TRMM_API_DIR}" && python3 manage.py migrate accounts --noinput)
  fi

  if [[ "${RESTART_SERVICES}" == "true" ]] && command -v systemctl >/dev/null 2>&1; then
    log "Redémarrage des services TacticalRMM"
    systemctl restart rmm.service rmm-daphne.service rmmcelery.service rmmcelerybeat.service 2>/dev/null || \
      systemctl restart rmm rmm-daphne rmmcelery rmmcelerybeat 2>/dev/null || \
      log "Redémarrage manuel requis: systemctl restart rmm rmm-daphne rmmcelery rmmcelerybeat"
  fi

  log "Patches backend appliqués — champ ui_theme disponible"
}

main "$@"
