#!/bin/bash
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

# Needed because if it is set, cd may print the path it changed to.
unset CDPATH

# On Mac OS, readlink -f doesn't work, so follow_links traverses the path one
# link at a time, and then cds into the link destination and find out where it
# ends up.
#
# The function is enclosed in a subshell to avoid changing the working directory
# of the caller.
function follow_links() (
  cd -P "$(dirname -- "$1")"
  file="$PWD/$(basename -- "$1")"
  while [[ -h "$file" ]]; do
    cd -P "$(dirname -- "$file")"
    file="$(readlink -- "$file")"
    cd -P "$(dirname -- "$file")"
    file="$PWD/$(basename -- "$file")"
  done
  echo "$file"
)

function dart_bin() {
  dart_path="$1/flutter/third_party/dart/tools/sdks/dart-sdk/bin"
  if [[ ! -e "$dart_path" ]]; then
    dart_path="$1/third_party/dart/tools/sdks/dart-sdk/bin"
  fi
  echo "$dart_path"
}

SCRIPT_DIR=$(follow_links "$(dirname -- "${BASH_SOURCE[0]}")")
SRC_DIR="$(cd "$SCRIPT_DIR/../.."; pwd -P)"
FLUTTER_DIR="$(cd "$SCRIPT_DIR/.."; pwd -P)"
DART_BIN=$(dart_bin "$SRC_DIR")
DART="${DART_BIN}/dart"

# FLUTTER_LINT_PRINT_FIX will make it so that fix is executed and the generated
# diff is printed to stdout if clang-tidy fails. This is helpful for enabling
# new lints.

# To run on CI, just uncomment the following line:
# FLUTTER_LINT_PRINT_FIX=1

if [[ -z "${FLUTTER_LINT_PRINT_FIX}" ]]; then
  fix_flag=""
else
  fix_flag="--fix --lint-all"
fi

# Determine whether to use x64 or arm64.
if command -v arch &> /dev/null && [[ $(arch) == "arm64" ]]; then
  CLANG_TIDY_PATH="flutter/buildtools/mac-arm64/clang/bin/clang-tidy"
fi

# The build directories this run reads: --variant (or --target-variant), the
# lint's own, and --shard-variants, the ones its shards are computed against.
# Read here only to find them; the arguments go to the tool as they are.
variants=()
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[$i]}" in
    --variant|--target-variant)
      variants+=("${args[$((i + 1))]}")
      ;;
    --variant=*|--target-variant=*)
      variants+=("${args[$i]#*=}")
      ;;
    --shard-variants)
      IFS=',' read -r -a shard_variants <<< "${args[$((i + 1))]}"
      variants+=("${shard_variants[@]}")
      ;;
    --shard-variants=*)
      IFS=',' read -r -a shard_variants <<< "${args[$i]#*=}"
      variants+=("${shard_variants[@]}")
      ;;
  esac
done

# A build directory tools/gn --bazel wrote (bazel.json in it) has no
# compile_commands.json: GN writes one at gn gen, Bazel none. It is made here
# from the build's own action graph (bazel aquery on the build's server and
# configuration; tools/gn_to_bazel/tool/compile_commands.py), after a build
# of the targets the query covers (--build), so that the generated headers
# the commands include are on disk even when the build's actions ran
# remotely. The database names the execution root of the machine that
# built: the recipe runs this script as a build-local test step on the
# drone that built, not as a global test over an archive of the directory.
# A failed database fails the step (set -e). The GN fallback below (a
# throwaway `tools/gn` when out/host_debug has no database) is for GN
# directories alone.
bazel_variants=()
for variant in "${variants[@]}"; do
  if [ -n "$variant" ] && [ -f "$SRC_DIR/out/$variant/bazel.json" ] \
      && [[ " ${bazel_variants[*]} " != *" $variant "* ]]; then
    bazel_variants+=("$variant")
  fi
done
for variant in "${bazel_variants[@]}"; do
  echo "$(date +%T) Writing out/$variant/compile_commands.json from the Bazel build"
  python3 "$SRC_DIR/flutter/tools/gn_to_bazel/tool/compile_commands.py" \
    --build-directory="$SRC_DIR/out/$variant" --build
done

COMPILE_COMMANDS="$SRC_DIR/out/host_debug/compile_commands.json"
if [ ${#bazel_variants[@]} -eq 0 ] && [ ! -f "$COMPILE_COMMANDS" ]; then
  (cd "$SRC_DIR"; ./flutter/tools/gn)
fi

echo "$(date +%T) Running clang_tidy"

cd "$SCRIPT_DIR"
"$DART" \
  "$SRC_DIR/flutter/tools/clang_tidy/bin/main.dart" \
  --src-dir="$SRC_DIR" \
  ${CLANG_TIDY_PATH:+--clang-tidy="$SRC_DIR/$CLANG_TIDY_PATH"} \
  $fix_flag \
  "$@" && true # errors ignored
clang_tidy_return=$?
if [ $clang_tidy_return -ne 0 ]; then
  if [ -n "$fix_flag" ]; then
    echo "###################################################"
    echo "# Attempted to fix issues with the following patch:"
    echo "###################################################"
    git --no-pager diff
  fi
  exit $clang_tidy_return
fi
