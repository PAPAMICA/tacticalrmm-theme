#!/usr/bin/env bash
# Apply backend patches for UI theme preference (Django).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TRMM_API_DIR="${TRMM_API_DIR:-/rmm/api/tacticalrmm}"
TRMM_VENV="${TRMM_VENV:-}"
RESTART_SERVICES="${RESTART_SERVICES:-true}"

log() {
  echo "[dracula-backend] $*"
}

die() {
  echo "[dracula-backend] ERROR: $*" >&2
  exit 1
}

detect_python() {
  local candidate

  if [[ -n "${TRMM_VENV}" && -x "${TRMM_VENV}/bin/python" ]]; then
    echo "${TRMM_VENV}/bin/python"
    return
  fi

  for candidate in \
    "/rmm/api/env/bin/python" \
    "${TRMM_API_DIR}/../env/bin/python" \
    "${TRMM_API_DIR}/env/bin/python" \
    "${TRMM_API_DIR}/venv/bin/python"
  do
    if [[ -x "${candidate}" ]]; then
      echo "${candidate}"
      return
    fi
  done

  die "Python Django introuvable. Définissez TRMM_VENV (ex: /rmm/api/env) ou activez le venv TacticalRMM."
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
  elif [[ -f "${migration_dst}" ]]; then
    log "Migration 0041_user_ui_theme.py déjà présente"
  fi

  local python_bin
  python_bin="$(detect_python)"
  log "Python Django: ${python_bin}"

  log "Exécution de la migration Django"
  (cd "${TRMM_API_DIR}" && "${python_bin}" manage.py migrate accounts --noinput)

  if [[ "${RESTART_SERVICES}" == "true" ]] && command -v systemctl >/dev/null 2>&1; then
    log "Redémarrage des services TacticalRMM"
    systemctl restart rmm.service rmm-daphne.service rmmcelery.service rmmcelerybeat.service 2>/dev/null || \
      systemctl restart rmm rmm-daphne rmmcelery rmmcelerybeat 2>/dev/null || \
      log "Redémarrage manuel requis: systemctl restart rmm rmm-daphne rmmcelery rmmcelerybeat"
  fi

  log "Patches backend appliqués — champ ui_theme disponible"
}

main "$@"
