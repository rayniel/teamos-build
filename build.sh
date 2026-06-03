#!/usr/bin/env bash
set -euo pipefail

echo "[1/3] clean"
sudo lb clean --purge || true

echo "[2/3] config"
lb config

echo "[3/3] build"
sudo lb build
