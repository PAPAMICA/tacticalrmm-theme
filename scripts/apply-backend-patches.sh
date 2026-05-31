#!/usr/bin/env bash
# Apply backend patches for UI theme preference (Django).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TRMM_API_DIR="${TRMM_API_DIR:-/rmm/api/tacticalrmm}"
TRMM_VENV="${TRMM_VENV:-}"
RESTART_SERVICES="${RESTART_SERVICES:-true}"

log() {
  echo "[trmm-theme-backend] $*"
}

die() {
  echo "[trmm-theme-backend] ERROR: $*" >&2
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

  die "Django Python not found. Set TRMM_VENV (e.g. /rmm/api/env) or activate the TacticalRMM virtualenv."
}

main() {
  [[ -d "${TRMM_API_DIR}" ]] || die "API directory not found: ${TRMM_API_DIR}"

  local patch
  for patch in "${THEME_DIR}"/patches-backend/*.patch; do
    [[ -f "${patch}" ]] || continue
    log "Applying $(basename "${patch}")"
    git -C "${TRMM_API_DIR}" apply --check "${patch}" 2>/dev/null || {
      log "  (already applied or conflict — retrying apply)"
    }
    git -C "${TRMM_API_DIR}" apply "${patch}" 2>/dev/null || log "  → skipped (likely already applied)"
  done

  local migration_src="${THEME_DIR}/patches-backend/accounts/migrations/0041_user_ui_theme.py"
  local migration_dst="${TRMM_API_DIR}/accounts/migrations/0041_user_ui_theme.py"
  if [[ -f "${migration_src}" && ! -f "${migration_dst}" ]]; then
    cp "${migration_src}" "${migration_dst}"
    log "Migration 0041_user_ui_theme.py installed"
  elif [[ -f "${migration_dst}" ]]; then
    log "Migration 0041_user_ui_theme.py already present"
  fi

  local python_bin
  python_bin="$(detect_python)"
  log "Django Python: ${python_bin}"

  log "Running Django migration"
  (cd "${TRMM_API_DIR}" && "${python_bin}" manage.py migrate accounts --noinput)

  if [[ "${RESTART_SERVICES}" == "true" ]] && command -v systemctl >/dev/null 2>&1; then
    log "Restarting TacticalRMM services"
    systemctl restart rmm.service rmm-daphne.service rmmcelery.service rmmcelerybeat.service 2>/dev/null || \
      systemctl restart rmm rmm-daphne rmmcelery rmmcelerybeat 2>/dev/null || \
      log "Manual restart required: systemctl restart rmm rmm-daphne rmmcelery rmmcelerybeat"
  fi

  log "Backend patches applied — ui_theme field is available"
}

main "$@"
