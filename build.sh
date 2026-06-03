#!/usr/bin/env bash
set -euo pipefail

echo "[1/3] clean"
sudo lb clean --purge || true

echo "[2/3] config"
lb config \
  --architecture amd64 \
  --distribution bookworm \
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
sudo lb build
