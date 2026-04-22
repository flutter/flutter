#!/bin/sh

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ENGINE_SRC="$ROOT_DIR/engine/src"
OUT_DIR="out/host_debug_unopt_gtk3"
TEST_TARGET="flutter/shell/platform/linux:flutter_linux_unittests"
TEST_BINARY="$ENGINE_SRC/$OUT_DIR/flutter_linux_unittests"
DEFAULT_FILTER="FlAccessibilityHandlerTest.*:FlAccessibleNodeTest.*:FlAccessibleTextFieldTest.*:FlViewAccessibleTest.*:FlAccessibilitySemanticsStoreTest.*"
GTEST_FILTER_VALUE="${1:-${GTEST_FILTER:-$DEFAULT_FILTER}}"

cd "$ENGINE_SRC"

VPYTHON_BYPASS="manually managed python not supported by chrome operations" \
  ninja -C "$OUT_DIR" "$TEST_TARGET"

if [ ! -x "$TEST_BINARY" ]; then
  echo "Expected test binary not found: $TEST_BINARY" >&2
  exit 1
fi

exec "$TEST_BINARY" --gtest_filter="$GTEST_FILTER_VALUE"
