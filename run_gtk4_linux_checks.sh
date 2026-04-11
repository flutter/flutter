#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_SRC="$ROOT/engine/src"
OUT_DIR="${GTK4_LINUX_OUT_DIR:-out/host_debug_unopt}"
FLUTTER_BIN="$ROOT/bin/flutter"

run() {
  echo
  echo "==> $*"
  "$@"
}

run_engine_build_checks() {
  run ninja -C "$OUT_DIR" build.ninja.stamp
  run ninja -C "$OUT_DIR" libflutter_linux_gtk.so -k 1
}

run_flutter_tools_checks() {
  cd "$ROOT/packages/flutter_tools"

  run ../../bin/flutter test --no-pub \
    test/commands.shard/permeable/create_test.dart \
    --plain-name "app supports Linux if requested"

  run ../../bin/flutter test --no-pub \
    test/commands.shard/permeable/create_test.dart \
    --plain-name "app supports Linux GTK3 if requested"

  run ../../bin/flutter test --no-pub \
    test/commands.shard/permeable/create_test.dart \
    --plain-name "plugin supports Linux if requested"

  run ../../bin/flutter test --no-pub \
    test/integration.shard/flutter_create_linux_gtk4_build_test.dart
}

usage() {
  cat <<'EOF'
Usage:
  ./run_gtk4_linux_checks.sh [engine|tools|all]

Modes:
  engine  Run focused GTK4 Linux engine build checks only.
  tools   Run focused flutter_tools GTK/Linux template tests only.
  all     Run both sets of checks. This is the default.

Environment:
  GTK4_LINUX_OUT_DIR  Override the engine output directory.
                      Default: out/host_debug_unopt
EOF
}

main() {
  local mode="${1:-all}"

  case "$mode" in
    engine)
      cd "$ENGINE_SRC"
      run_engine_build_checks
      ;;
    tools)
      run_flutter_tools_checks
      ;;
    all)
      cd "$ENGINE_SRC"
      run_engine_build_checks
      run_flutter_tools_checks
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      echo "Unknown mode: $mode" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
