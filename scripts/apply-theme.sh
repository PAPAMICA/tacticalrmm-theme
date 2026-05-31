#!/usr/bin/env bash
# Apply Dracula theme to TacticalRMM by rebuilding tacticalrmm-web with patches.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TRMM_WEB_REPO="${TRMM_WEB_REPO:-https://github.com/amidaware/tacticalrmm-web.git}"
TRMM_SETTINGS="${TRMM_SETTINGS:-/rmm/api/tacticalrmm/tacticalrmm/settings.py}"
TRMM_DIST_PATH="${TRMM_DIST_PATH:-/var/www/rmm/dist}"
TRMM_BUILD_DIR="${TRMM_BUILD_DIR:-/tmp/tacticalrmm-web-dracula-build}"
TRMM_WEB_VERSION="${TRMM_WEB_VERSION:-}"
SKIP_NGINX_RELOAD="${SKIP_NGINX_RELOAD:-false}"
DRY_RUN="${DRY_RUN:-false}"

log() {
  echo "[dracula-theme] $*"
}

die() {
  echo "[dracula-theme] ERROR: $*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Commande requise introuvable: $1"
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

  die "Impossible de détecter WEB_VERSION. Définissez TRMM_WEB_VERSION ou TRMM_SETTINGS."
}

prepare_build_dir() {
  local tag="v${WEB_VERSION}"

  if [[ -d "${TRMM_BUILD_DIR}/.git" ]]; then
    log "Réutilisation du répertoire de build ${TRMM_BUILD_DIR}"
    git -C "${TRMM_BUILD_DIR}" fetch --tags origin
    git -C "${TRMM_BUILD_DIR}" reset --hard
    git -C "${TRMM_BUILD_DIR}" clean -fdx
    git -C "${TRMM_BUILD_DIR}" checkout "${tag}" 2>/dev/null || git -C "${TRMM_BUILD_DIR}" checkout "tags/${tag}"
  else
    log "Clone de ${TRMM_WEB_REPO} (tag ${tag})"
    rm -rf "${TRMM_BUILD_DIR}"
    git clone --depth 1 --branch "${tag}" "${TRMM_WEB_REPO}" "${TRMM_BUILD_DIR}" 2>/dev/null || {
      git clone "${TRMM_WEB_REPO}" "${TRMM_BUILD_DIR}"
      git -C "${TRMM_BUILD_DIR}" fetch --tags origin
      git -C "${TRMM_BUILD_DIR}" checkout "${tag}" 2>/dev/null || git -C "${TRMM_BUILD_DIR}" checkout "tags/${tag}"
    }
  fi
}

apply_patches() {
  log "Application des patches Dracula"
  cp "${THEME_DIR}/palette/dracula.sass" "${TRMM_BUILD_DIR}/src/css/dracula.sass"

  local patch
  for patch in "${THEME_DIR}"/patches/*.patch; do
    log "  → $(basename "${patch}")"
    git -C "${TRMM_BUILD_DIR}" apply --check "${patch}"
    git -C "${TRMM_BUILD_DIR}" apply "${patch}"
  done

  cp "${THEME_DIR}/assets/favicon.ico" "${TRMM_BUILD_DIR}/public/favicon.ico"
  log "Favicon Dracula installé"
}

build_frontend() {
  log "Installation des dépendances npm"
  cd "${TRMM_BUILD_DIR}"
  if [[ -f package-lock.json ]]; then
    npm ci
  else
    npm install
  fi

  log "Build Quasar (peut prendre plusieurs minutes)"
  npx quasar build
}

deploy_dist() {
  local build_output="${TRMM_BUILD_DIR}/dist"

  [[ -d "${build_output}" ]] || die "Répertoire de build introuvable: ${build_output}"

  if [[ "${DRY_RUN}" == "true" ]]; then
    log "[DRY RUN] Déploiement simulé vers ${TRMM_DIST_PATH}"
    return
  fi

  if [[ ! -w "$(dirname "${TRMM_DIST_PATH}")" ]] && [[ "$(id -u)" -ne 0 ]]; then
    die "Permissions insuffisantes pour écrire dans ${TRMM_DIST_PATH}. Exécutez avec sudo."
  fi

  local backup="${TRMM_DIST_PATH}.bak.$(date +%s)"
  if [[ -d "${TRMM_DIST_PATH}" ]]; then
    log "Sauvegarde de ${TRMM_DIST_PATH} → ${backup}"
    mv "${TRMM_DIST_PATH}" "${backup}"
  fi

  mkdir -p "${TRMM_DIST_PATH}"
  cp -a "${build_output}/." "${TRMM_DIST_PATH}/"
  chown -R www-data:www-data "${TRMM_DIST_PATH}" 2>/dev/null || true

  log "Frontend déployé dans ${TRMM_DIST_PATH}"
}

reload_nginx() {
  if [[ "${SKIP_NGINX_RELOAD}" == "true" ]]; then
    log "Rechargement nginx ignoré (SKIP_NGINX_RELOAD=true)"
    return
  fi

  if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet nginx 2>/dev/null; then
    log "Rechargement de nginx"
    systemctl reload nginx
  else
    log "nginx non actif ou systemctl indisponible — rechargement ignoré"
  fi
}

main() {
  require_cmd git
  require_cmd npm
  require_cmd npx

  WEB_VERSION="$(detect_web_version)"
  log "Version tacticalrmm-web ciblée: ${WEB_VERSION}"

  local supported
  supported="$(cat "${THEME_DIR}/SUPPORTED_WEB_VERSION" 2>/dev/null || echo "")"
  if [[ -n "${supported}" && "${WEB_VERSION}" != "${supported}" ]]; then
    log "ATTENTION: ce thème a été testé avec WEB_VERSION=${supported}, votre serveur utilise ${WEB_VERSION}."
    log "Les patches peuvent échouer — vérifiez SUPPORTED_WEB_VERSION ou mettez à jour le dépôt du thème."
  fi

  prepare_build_dir
  apply_patches
  build_frontend
  deploy_dist
  reload_nginx

  mkdir -p "${THEME_DIR}/.state"
  echo "${WEB_VERSION}" > "${THEME_DIR}/.state/last-applied-version"

  log "Thème Dracula appliqué avec succès (WEB_VERSION=${WEB_VERSION})"
}

main "$@"
