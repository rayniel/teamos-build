#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

artifact_input="${1:-}"
tmp_dir=""

cleanup() {
  [[ -n "$tmp_dir" && -d "$tmp_dir" ]] && rm -rf "$tmp_dir"
}
trap cleanup EXIT

pick_artifact() {
  if [[ -n "$artifact_input" ]]; then
    printf '%s\n' "$artifact_input"
    return 0
  fi

  local candidate
  for candidate in \
    "$repo_root"/out/artifacts/*.iso \
    "$repo_root"/out/work/live-image-*.hybrid.iso \
    "$repo_root"/out/work/binary/live/filesystem.packages; do
    [[ -e "$candidate" ]] || continue
    printf '%s\n' "$candidate"
    return 0
  done

  return 1
}

extract_package_manifest() {
  local artifact="$1"
  local manifest_out="$2"

  if [[ "$artifact" == *.packages ]]; then
    cp "$artifact" "$manifest_out"
    return 0
  fi

  if [[ "$artifact" != *.iso ]]; then
    echo "Unsupported artifact: $artifact" >&2
    return 1
  fi

  if ! command -v xorriso >/dev/null 2>&1; then
    echo "xorriso is required to inspect ISO artifacts." >&2
    return 1
  fi

  xorriso -osirrox on -indev "$artifact" -extract /live/filesystem.packages "$manifest_out" >/dev/null 2>&1
}

artifact="$(pick_artifact || true)"
if [[ -z "$artifact" ]]; then
  echo "No build artifact found. Expected an ISO under out/artifacts/ or a manifest under out/work/binary/live/." >&2
  exit 2
fi

if [[ ! -e "$artifact" ]]; then
  echo "Artifact does not exist: $artifact" >&2
  exit 2
fi

tmp_dir="$(mktemp -d)"
manifest_file="$tmp_dir/filesystem.packages"
extract_package_manifest "$artifact" "$manifest_file"

required_packages=(
  lightdm
  openbox
  tint2
  rofi
  pcmanfm
  alacritty
  nitrogen
  picom
  network-manager-gnome
  pasystray
  lxpolkit
  fcitx5
)

missing_packages=()
for package_name in "${required_packages[@]}"; do
  if ! awk -v package_name="$package_name" '$1 == package_name { found=1; exit } END { exit found ? 0 : 1 }' "$manifest_file"; then
    missing_packages+=("$package_name")
  fi
done

echo "Artifact: $artifact"
echo "Manifest: $manifest_file"

if (( ${#missing_packages[@]} > 0 )); then
  echo "Missing packages:" >&2
  printf '  %s\n' "${missing_packages[@]}" >&2
  exit 1
fi

echo "All required desktop packages are present."