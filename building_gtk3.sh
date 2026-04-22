#!/bin/sh

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ENGINE_SRC="$ROOT_DIR/engine/src"
OUT_DIR="out/host_debug_unopt_gtk3"

cd "$ENGINE_SRC"

VPYTHON_BYPASS="manually managed python not supported by chrome operations" \
  python3 flutter/tools/gn \
  --unoptimized \
  --runtime-mode=debug \
  --no-lto \
  --target-dir host_debug_unopt_gtk3 \
  --gn-args="use_gtk4=false"

VPYTHON_BYPASS="manually managed python not supported by chrome operations" \
  ninja -C "$OUT_DIR"
