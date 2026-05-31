#!/usr/bin/env bash
# Apply TacticalRMM UI themes by rebuilding tacticalrmm-web with patches.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TRMM_WEB_REPO="${TRMM_WEB_REPO:-https://github.com/amidaware/tacticalrmm-web.git}"
TRMM_SETTINGS="${TRMM_SETTINGS:-/rmm/api/tacticalrmm/tacticalrmm/settings.py}"
TRMM_MANAGE_DIR="${TRMM_MANAGE_DIR:-/rmm/api/tacticalrmm}"
TRMM_DIST_PATH="${TRMM_DIST_PATH:-/var/www/rmm/dist}"
TRMM_BUILD_DIR="${TRMM_BUILD_DIR:-/tmp/tacticalrmm-web-theme-build}"
TRMM_WEB_VERSION="${TRMM_WEB_VERSION:-}"
SKIP_NGINX_RELOAD="${SKIP_NGINX_RELOAD:-false}"
DRY_RUN="${DRY_RUN:-false}"

log() {
  echo "[trmm-theme] $*"
}

die() {
  echo "[trmm-theme] ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

detect_web_version() {
  if [[ -n "${TRMM_WEB_VERSION}" ]]; then
    echo "${TRMM_WEB_VERSION}"
    return
  fi

  if [[ -f "${TRMM_SETTINGS}" ]]; then
    local version
    version="$(grep -E '^WEB_VERSION\s*=' "${TRMM_SETTINGS}" | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
    if [[ -n "${version}" ]]; then
      echo "${version}"
      return
    fi
  fi

  if [[ -f "${THEME_DIR}/SUPPORTED_WEB_VERSION" ]]; then
    cat "${THEME_DIR}/SUPPORTED_WEB_VERSION"
    return
  fi

  die "Unable to detect WEB_VERSION. Set TRMM_WEB_VERSION or TRMM_SETTINGS."
}

prepare_build_dir() {
  local tag="v${WEB_VERSION}"

  if [[ -d "${TRMM_BUILD_DIR}/.git" ]]; then
    log "Reusing build directory ${TRMM_BUILD_DIR}"
    git -C "${TRMM_BUILD_DIR}" fetch --tags origin
    git -C "${TRMM_BUILD_DIR}" reset --hard
    git -C "${TRMM_BUILD_DIR}" clean -fdx
    git -C "${TRMM_BUILD_DIR}" checkout "${tag}" 2>/dev/null || git -C "${TRMM_BUILD_DIR}" checkout "tags/${tag}"
  else
    log "Cloning ${TRMM_WEB_REPO} (tag ${tag})"
    rm -rf "${TRMM_BUILD_DIR}"
    git clone --depth 1 --branch "${tag}" "${TRMM_WEB_REPO}" "${TRMM_BUILD_DIR}" 2>/dev/null || {
      git clone "${TRMM_WEB_REPO}" "${TRMM_BUILD_DIR}"
      git -C "${TRMM_BUILD_DIR}" fetch --tags origin
      git -C "${TRMM_BUILD_DIR}" checkout "${tag}" 2>/dev/null || git -C "${TRMM_BUILD_DIR}" checkout "tags/${tag}"
    }
  fi
}

copy_themes() {
  log "Copying theme pack"
  rm -rf "${TRMM_BUILD_DIR}/src/css/themes"
  cp -R "${THEME_DIR}/themes" "${TRMM_BUILD_DIR}/src/css/themes"
}

apply_patches() {
  log "Applying frontend patches"
  copy_themes

  local patch
  for patch in "${THEME_DIR}"/patches/*.patch; do
    log "  → $(basename "${patch}")"
    git -C "${TRMM_BUILD_DIR}" apply --check "${patch}"
    git -C "${TRMM_BUILD_DIR}" apply "${patch}"
  done

  cp "${THEME_DIR}/assets/favicon.ico" "${TRMM_BUILD_DIR}/public/favicon.ico"
}

detect_api_domain() {
  local api=""

  if [[ -n "${PROD_URL:-}" ]]; then
    local url="${PROD_URL#https://}"
    url="${url#http://}"
    echo "${url}"
    return
  fi

  if [[ -d "${TRMM_MANAGE_DIR}" ]]; then
    api="$(cd "${TRMM_MANAGE_DIR}" && python3 manage.py get_config api 2>/dev/null || true)"
    if [[ -n "${api}" ]]; then
      echo "${api}"
      return
    fi
  fi

  local local_settings="${TRMM_MANAGE_DIR}/tacticalrmm/local_settings.py"
  if [[ -f "${local_settings}" ]]; then
    api="$(grep -E 'ALLOWED_HOSTS' "${local_settings}" | head -1 | sed -E 's/.*\["([^"]+)".*/\1/')"
    if [[ -n "${api}" ]]; then
      echo "${api}"
      return
    fi
  fi

  echo ""
}

write_env_config() {
  local source="$1"
  local api_domain

  api_domain="$(detect_api_domain)"
  [[ -n "${api_domain}" ]] || die "Unable to create env-config.js. Copy it from a dist.bak.* backup or set PROD_URL."

  echo "window._env_ = {PROD_URL: \"https://${api_domain}\"}" > "${TRMM_DIST_PATH}/env-config.js"
  log "env-config.js ${source} (PROD_URL=https://${api_domain})"
}

restore_env_config() {
  local env_config_backup="$1"
  local dist_backup="$2"

  if [[ -n "${env_config_backup}" && -f "${env_config_backup}" ]]; then
    cp "${env_config_backup}" "${TRMM_DIST_PATH}/env-config.js"
    log "env-config.js restored from previous deployment"
    return
  fi

  if [[ -n "${dist_backup}" && -f "${dist_backup}/env-config.js" ]]; then
    cp "${dist_backup}/env-config.js" "${TRMM_DIST_PATH}/env-config.js"
    log "env-config.js restored from ${dist_backup}"
    return
  fi

  write_env_config "generated"
}

deploy_dist() {
  local build_output="${TRMM_BUILD_DIR}/dist"

  [[ -d "${build_output}" ]] || die "Build output directory not found: ${build_output}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[DRY RUN] Simulated deployment to ${TRMM_DIST_PATH}"
    return
  fi

  if [[ ! -w "$(dirname "${TRMM_DIST_PATH}")" ]] && [[ "$(id -u)" -ne 0 ]]; then
    die "Insufficient permissions to write to ${TRMM_DIST_PATH}. Run with sudo."
  fi

  local env_config_backup=""
  local dist_backup=""
  if [[ -f "${TRMM_DIST_PATH}/env-config.js" ]]; then
    env_config_backup="$(mktemp)"
    cp "${TRMM_DIST_PATH}/env-config.js" "${env_config_backup}"
  fi

  local backup="${TRMM_DIST_PATH}.bak.$(date +%s)"
  if [[ -d "${TRMM_DIST_PATH}" ]]; then
    log "Backing up ${TRMM_DIST_PATH} → ${backup}"
    mv "${TRMM_DIST_PATH}" "${backup}"
    dist_backup="${backup}"
    mkdir -p "${THEME_DIR}/.state"
    echo "${backup}" > "${THEME_DIR}/.state/last-backup"
  fi

  mkdir -p "${TRMM_DIST_PATH}"
  cp -a "${build_output}/." "${TRMM_DIST_PATH}/"
  restore_env_config "${env_config_backup}" "${dist_backup}"
  [[ -n "${env_config_backup}" ]] && rm -f "${env_config_backup}"
  chown -R www-data:www-data "${TRMM_DIST_PATH}" 2>/dev/null || true

  log "Frontend deployed to ${TRMM_DIST_PATH}"
}

build_frontend() {
  log "Installing npm dependencies"
  cd "${TRMM_BUILD_DIR}"
  if [[ -f package-lock.json ]]; then
    npm ci
  else
    npm install
  fi

  log "Running Quasar build (this may take several minutes)"
  npx quasar build
}

reload_nginx() {
  if [[ "${SKIP_NGINX_RELOAD}" == "true" ]]; then
    return
  fi

  if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet nginx 2>/dev/null; then
    log "Reloading nginx"
    systemctl reload nginx
  fi
}

main() {
  require_cmd git
  require_cmd npm
  require_cmd npx

  WEB_VERSION="$(detect_web_version)"
  log "Target tacticalrmm-web version: ${WEB_VERSION}"

  local supported
  supported="$(cat "${THEME_DIR}/SUPPORTED_WEB_VERSION" 2>/dev/null || echo "")"
  if [[ -n "${supported}" && "${WEB_VERSION}" != "${supported}" ]]; then
    log "WARNING: tested with WEB_VERSION=${supported}, server=${WEB_VERSION}"
  fi

  prepare_build_dir
  apply_patches
  build_frontend
  deploy_dist
  reload_nginx

  mkdir -p "${THEME_DIR}/.state"
  echo "${WEB_VERSION}" > "${THEME_DIR}/.state/last-applied-version"

  log "TacticalRMM themes deployed successfully"
}

main "$@"
