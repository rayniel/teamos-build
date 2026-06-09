#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build_root="${script_dir}/out"
work_dir="${build_root}/work"
artifacts_dir="${build_root}/artifacts"
log_file="${artifacts_dir}/build.log"
cache_store_dir="${build_root}/cache"
command="${1:-build}"

show_usage() {
  cat <<'EOF'
Usage:
  ./build.sh            Build image (reuse cache)
  ./build.sh build      Build image (reuse cache)
  ./build.sh clean      Clean workspace but keep shared cache
  ./build.sh clean-all  Clean workspace and all caches/artifacts
EOF
}

remove_path_best_effort() {
  local path="$1"
  [[ -e "$path" ]] || return 0

  if rm -rf "$path" 2>/dev/null; then
    return 0
  fi

  if sudo rm -rf "$path" 2>/dev/null; then
    return 0
  fi

  echo "Warning: could not remove path: $path" >&2
  return 0
}

normalize_out_ownership() {
  local user_uid group_gid
  user_uid="$(id -u)"
  group_gid="$(id -g)"

  # live-build runs with sudo and leaves root-owned files; return ownership to caller.
  sudo chown -R "${user_uid}:${group_gid}" "${work_dir}" "${artifacts_dir}" "${cache_store_dir}" 2>/dev/null || true
}

ensure_cache_link() {
  mkdir -p "${cache_store_dir}" "${work_dir}"
  remove_path_best_effort "${work_dir}/cache"
  ln -s "${cache_store_dir}" "${work_dir}/cache"
}

if [[ "${command}" == "clean" ]]; then
  echo "Cleaning build workspace (keeping shared cache): ${work_dir}"
  remove_path_best_effort "${work_dir}"
  mkdir -p "${work_dir}"
  ensure_cache_link
  normalize_out_ownership
  echo "Clean complete. Cache preserved. Artifacts kept at: ${artifacts_dir}"
  exit 0
fi

if [[ "${command}" == "clean-all" ]]; then
  echo "Cleaning workspace, artifacts, and cache: ${build_root}"
  rm -rf "${work_dir}" "${artifacts_dir}" "${cache_store_dir}"
  echo "Clean-all complete."
  exit 0
fi

if [[ "${command}" != "build" ]]; then
  show_usage
  exit 1
fi

mkdir -p "${work_dir}" "${artifacts_dir}"
rsync -a --delete "${script_dir}/config/" "${work_dir}/config/"
normalize_out_ownership

cd "${work_dir}"

ensure_cache_link

trap 'echo "Build failed. See ${log_file} for full output."' ERR

echo "[1/3] clean (keep cache)"
sudo lb clean || true
ensure_cache_link
normalize_out_ownership

echo "[2/3] config"
lb_config_args=(
  --architecture amd64
  --distribution trixie
  --binary-images iso-hybrid
  --debian-installer false
  --archive-areas "main contrib non-free non-free-firmware"
  --bootappend-live "boot=live components quiet splash username=user hostname=teamos"
  --iso-application "TeamOS Live"
  --iso-preparer "rayniel"
  --iso-publisher "rayniel"
  --iso-volume "TeamOS Live"
  --linux-flavours amd64
  --mirror-bootstrap http://mirrors.163.com/debian/
  --mirror-binary http://mirrors.163.com/debian/
  --mirror-chroot-security http://mirrors.163.com/debian-security/
  --mirror-binary-security http://mirrors.163.com/debian-security/
)
lb config "${lb_config_args[@]}"

echo "[3/3] build"
# Make chroot hooks executable (live-build requires this)
find config/hooks -name '*.hook.chroot' -exec chmod +x {} \; 2>/dev/null || true
chmod +x config/includes.chroot/usr/bin/teamos-session 2>/dev/null || true
chmod +x config/includes.chroot/usr/bin/teamos-* 2>/dev/null || true
chmod +x config/includes.chroot/etc/skel/.config/openbox/scripts/* 2>/dev/null || true
sudo lb build 2>&1 | tee "${log_file}"
build_status=${PIPESTATUS[0]}
normalize_out_ownership
if [[ ${build_status} -ne 0 ]]; then
  echo "lb build failed with exit code ${build_status}."
  exit "${build_status}"
fi

# Collect distributable files in a stable location under the project root.
find . -maxdepth 1 -type f -name 'live-image-*' -exec cp -f {} "${artifacts_dir}/" \;
find . -maxdepth 1 -type f -name '*.iso' -exec cp -f {} "${artifacts_dir}/" \;

echo "Build workspace: ${work_dir}"
echo "Build cache: ${cache_store_dir}"
echo "Build artifacts: ${artifacts_dir}"
