#!/usr/bin/env bash
set -euo pipefail

log_file="build.log"

trap 'echo "Build failed. See ${log_file} for full output."' ERR

echo "[1/3] clean"
sudo lb clean --purge || true

echo "[2/3] config"
lb config \
  --architecture amd64 \
  --distribution trixie \
  --binary-images iso-hybrid \
  --debian-installer false \
  --archive-areas "main contrib non-free non-free-firmware" \
  --bootappend-live "boot=live components quiet splash username=user hostname=teamos" \
  --iso-application "TeamOS Live" \
  --iso-preparer "rayniel" \
  --iso-publisher "rayniel" \
  --iso-volume "TeamOS Live" \
  --linux-flavours amd64 \
  --mirror-bootstrap http://deb.debian.org/debian/ \
  --mirror-binary http://deb.debian.org/debian/ \
  --mirror-chroot-security http://security.debian.org/debian-security/ \
  --mirror-binary-security http://security.debian.org/debian-security/

echo "[3/3] build"
# Make chroot hooks executable (live-build requires this)
find config/hooks -name '*.hook.chroot' -exec chmod +x {} \; 2>/dev/null || true
chmod +x config/includes.chroot/usr/bin/teamos-session 2>/dev/null || true
sudo lb build 2>&1 | tee "${log_file}"
build_status=${PIPESTATUS[0]}
if [[ ${build_status} -ne 0 ]]; then
  echo "lb build failed with exit code ${build_status}."
  exit "${build_status}"
fi
