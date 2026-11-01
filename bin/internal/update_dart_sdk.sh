#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


# ---------------------------------- NOTE ---------------------------------- #
#
# Please keep the logic in this file consistent with the logic in the
# `update_dart_sdk.ps1` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# -------------------------------------------------------------------------- #

set -e

FLUTTER_ROOT="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"

DART_SDK_PATH="$FLUTTER_ROOT/bin/cache/dart-sdk"
DART_SDK_PATH_OLD="$DART_SDK_PATH.old"
ENGINE_STAMP="$FLUTTER_ROOT/bin/cache/engine-dart-sdk.stamp"
OS="$(uname -s)"

ENGINE_VERSION_STAMP="$FLUTTER_ROOT/bin/cache/engine.stamp"
ENGINE_FALLBACK_STAMP="$FLUTTER_ROOT/bin/cache/engine_fallback.stamp"
ENGINE_VERSION=$(< "$ENGINE_VERSION_STAMP")
ENGINE_VERSION="${ENGINE_VERSION//[[:space:]]/}"
ENGINE_REALM=$(< "$FLUTTER_ROOT/bin/cache/engine.realm")
ENGINE_REALM="${ENGINE_REALM//[[:space:]]/}"

INSTALLED_ENGINE_VERSION=""
if [ -f "$ENGINE_STAMP" ]; then
  INSTALLED_ENGINE_VERSION=$(< "$ENGINE_STAMP")
  INSTALLED_ENGINE_VERSION="${INSTALLED_ENGINE_VERSION//[[:space:]]/}"
fi

if [ ! -f "$ENGINE_STAMP" ] || [ "$ENGINE_VERSION" != "$INSTALLED_ENGINE_VERSION" ]; then
  command -v curl > /dev/null 2>&1 || {
    >&2 echo
    >&2 echo 'Missing "curl" tool. Unable to download Dart SDK.'
    case "$OS" in
      Darwin)
        >&2 echo 'Consider running "brew install curl".'
        ;;
      Linux)
        >&2 echo 'Consider running "sudo apt-get install curl".'
        ;;
      *)
        >&2 echo "Please install curl."
        ;;
    esac
    echo
    exit 1
  }
  command -v unzip > /dev/null 2>&1 || {
    >&2 echo
    >&2 echo 'Missing "unzip" tool. Unable to extract Dart SDK.'
    case "$OS" in
      Darwin)
        echo 'Consider running "brew install unzip".'
        ;;
      Linux)
        echo 'Consider running "sudo apt-get install unzip".'
        ;;
      *)
        echo "Please install unzip."
        ;;
    esac
    echo
    exit 1
  }

  if [ -n "$FLUTTER_HOST_ARCH" ]; then
    # FLUTTER_HOST_ARCH can be set to override the host architecture detection.
    ARCH="$FLUTTER_HOST_ARCH"
  elif [ "$OS" = 'Darwin' ]; then
    # `uname -m` may be running in Rosetta mode, instead query sysctl
    # Allow non-zero exit so we can do control flow
    set +e
    # -n means only print value, not key
    QUERY="sysctl -n hw.optional.arm64"
    # Do not wrap $QUERY in double quotes, otherwise the args will be treated as
    # part of the command
    QUERY_RESULT=$($QUERY 2>/dev/null)
    if [ $? -eq 1 ]; then
      # If this command fails, we're certainly not on ARM
      ARCH='x64'
    elif [ "$QUERY_RESULT" = '0' ]; then
      # If this returns 0, we are also not on ARM
      ARCH='x64'
    elif [ "$QUERY_RESULT" = '1' ]; then
      ARCH='arm64'
    else
      >&2 echo "'$QUERY' returned unexpected output: '$QUERY_RESULT'"
      exit 1
    fi
    set -e
  else
    # On x64 stdout is "uname -m: x86_64"
    # On arm64 stdout is "uname -m: aarch64, arm64_v8a"
    case "$(uname -m)" in
      x86_64)
        ARCH="x64"
        ;;
      riscv64)
        ARCH="riscv64"
        ;;
      *)
        ARCH="arm64"
        ;;
    esac
  fi

  case "$OS" in
    Darwin)
      DART_ZIP_NAME="dart-sdk-darwin-${ARCH}.zip"
      IS_USER_EXECUTABLE="-perm +100"
      ;;
    Linux)
      DART_ZIP_NAME="dart-sdk-linux-${ARCH}.zip"
      IS_USER_EXECUTABLE="-perm /u+x"
      ;;
    MINGW* | MSYS* )
      DART_ZIP_NAME="dart-sdk-windows-x64.zip"
      IS_USER_EXECUTABLE="-perm /u+x"
      ;;
    *)
      echo "Unknown operating system. Cannot install Dart SDK."
      exit 1
      ;;
  esac

  >&2 echo "Downloading $OS $ARCH Dart SDK from Flutter engine $ENGINE_VERSION..."

  # Use the default find if possible.
  if [ -e /usr/bin/find ]; then
    FIND=/usr/bin/find
  else
    FIND=find
  fi

  DART_SDK_BASE_URL="${FLUTTER_STORAGE_BASE_URL:-https://storage.googleapis.com}${ENGINE_REALM:+/$ENGINE_REALM}"
  DART_SDK_URL="$DART_SDK_BASE_URL/flutter_infra_release/flutter/$ENGINE_VERSION/$DART_ZIP_NAME"

  # Create a temporary directory for extraction to ensure atomicity
  DART_SDK_PATH_TEMP="$FLUTTER_ROOT/bin/cache/dart-sdk.tmp"
  rm -rf -- "$DART_SDK_PATH_TEMP"
  mkdir -m 755 -p -- "$DART_SDK_PATH_TEMP"

  DART_SDK_ZIP="$FLUTTER_ROOT/bin/cache/$DART_ZIP_NAME"

  # Conditionally set verbose flag for LUCI
  verbose_curl=""
  if [[ -n "$LUCI_CI" ]]; then
    verbose_curl="--verbose"
  fi

  download_dart_sdk() {
    local url="$1"
    curl ${verbose_curl} --fail --retry 3 --continue-at - --location --output "$DART_SDK_ZIP" "$url" 2>&1 || {
      local curlExitCode=$?
      # Handle range errors specially: retry again with disabled ranges (`--continue-at -` argument)
      # When this could happen:
      # - missing support of ranges in proxy servers
      # - curl with broken handling of completed downloads
      #   This is not a proper fix, but doesn't require any user input
      # - mirror of flutter storage without support of ranges
      #
      # 33  HTTP range error. The range "command" didn't work.
      # https://man7.org/linux/man-pages/man1/curl.1.html#EXIT_CODES
      if [ "$curlExitCode" -ne 33 ]; then
        return "$curlExitCode"
      fi
      curl ${verbose_curl} --fail --retry 3 --location --output "$DART_SDK_ZIP" "$url" 2>&1
    }
  }

  write_fallback_stamps() {
    local target_version="$1"
    local actual_version="$2"
    local fb_tmp="$ENGINE_FALLBACK_STAMP.tmp.$$"
    local es_tmp="$ENGINE_VERSION_STAMP.tmp.$$"
    echo "${target_version}:${actual_version}" > "$fb_tmp" && mv "$fb_tmp" "$ENGINE_FALLBACK_STAMP"
    echo "${actual_version}" > "$es_tmp" && mv "$es_tmp" "$ENGINE_VERSION_STAMP"
  }

  ORIGINAL_ENGINE_VERSION=""
  if ! download_dart_sdk "$DART_SDK_URL"; then
    rm -f -- "$DART_SDK_ZIP"

    STRICT_ENGINE_VERSION=false
    case "${FLUTTER_STRICT_ENGINE_VERSION}" in
      1|[Tt][Rr][Uu][Ee])
        STRICT_ENGINE_VERSION=true
        ;;
      0|[Ff][Aa][Ll][Ss][Ee])
        STRICT_ENGINE_VERSION=false
        ;;
      *)
        if [ -n "${LUCI_CONTEXT}" ]; then
          STRICT_ENGINE_VERSION=true
        fi
        ;;
    esac

    FALLBACK_ENGINE_VERSION=""
    if [ "$STRICT_ENGINE_VERSION" = "false" ] && [ -z "$ENGINE_REALM" ] && [ -z "$FLUTTER_PREBUILT_ENGINE_VERSION" ]; then
      unset GIT_DIR
      unset GIT_INDEX_FILE
      unset GIT_WORK_TREE
      if [ -z "$(git -C "$FLUTTER_ROOT" ls-files bin/internal/engine.version 2>/dev/null)" ]; then
        set +e
        MERGEBASE=$(git -C "$FLUTTER_ROOT" merge-base HEAD upstream/master 2>/dev/null || \
          git -C "$FLUTTER_ROOT" merge-base HEAD origin/master 2>/dev/null || \
          git -C "$FLUTTER_ROOT" merge-base HEAD upstream/main 2>/dev/null || \
          git -C "$FLUTTER_ROOT" merge-base HEAD origin/main 2>/dev/null)
        if [ -n "$MERGEBASE" ]; then
          FALLBACK_ENGINE_VERSION=$("$FLUTTER_ROOT/bin/internal/content_aware_hash.sh" "$MERGEBASE" 2>/dev/null)
          FALLBACK_ENGINE_VERSION="${FALLBACK_ENGINE_VERSION//[[:space:]]/}"
        fi
        set -e
      fi
    fi

    if [ -n "$FALLBACK_ENGINE_VERSION" ] && [ "$FALLBACK_ENGINE_VERSION" != "$ENGINE_VERSION" ]; then
      >&2 echo "================================================================================"
      >&2 echo "WARNING: Engine artifacts for $ENGINE_VERSION are not available."
      >&2 echo "This usually happens when you have local engine changes or are on a commit that"
      >&2 echo "has not finished building on CI yet."
      >&2 echo "Falling back to engine artifacts from merge-base ($FALLBACK_ENGINE_VERSION)."
      >&2 echo "Set FLUTTER_STRICT_ENGINE_VERSION=true to fail instead of falling back, or"
      >&2 echo "delete bin/cache/engine_fallback.stamp to retry downloading $ENGINE_VERSION."
      >&2 echo "================================================================================"
      ORIGINAL_ENGINE_VERSION="$ENGINE_VERSION"
      ENGINE_VERSION="$FALLBACK_ENGINE_VERSION"

      if [ -f "$ENGINE_STAMP" ] && [ "$ENGINE_VERSION" = "$INSTALLED_ENGINE_VERSION" ] && [ -d "$DART_SDK_PATH" ]; then
        rm -rf -- "$DART_SDK_PATH_TEMP"
        write_fallback_stamps "$ORIGINAL_ENGINE_VERSION" "$ENGINE_VERSION"
        exit 0
      fi

      DART_SDK_URL="$DART_SDK_BASE_URL/flutter_infra_release/flutter/$ENGINE_VERSION/$DART_ZIP_NAME"
      >&2 echo "Downloading $OS $ARCH Dart SDK from Flutter engine $ENGINE_VERSION..."
      download_dart_sdk "$DART_SDK_URL" || {
        >&2 echo
        >&2 echo "Failed to retrieve the Dart SDK from: $DART_SDK_URL"
        >&2 echo "If you're located in China, please see this page:"
        >&2 echo "  https://flutter.dev/community/china"
        >&2 echo
        rm -f -- "$DART_SDK_ZIP"
        rm -rf -- "$DART_SDK_PATH_TEMP"
        exit 1
      }
    else
      >&2 echo
      >&2 echo "Failed to retrieve the Dart SDK from: $DART_SDK_URL"
      >&2 echo "If you're located in China, please see this page:"
      >&2 echo "  https://flutter.dev/community/china"
      >&2 echo
      rm -f -- "$DART_SDK_ZIP"
      rm -rf -- "$DART_SDK_PATH_TEMP"
      exit 1
    fi
  fi

  unzip -o -q "$DART_SDK_ZIP" -d "$DART_SDK_PATH_TEMP" || {
    >&2 echo
    >&2 echo "It appears that the downloaded file is corrupt; please try again."
    >&2 echo "If this problem persists, please report the problem at:"
    >&2 echo "  https://github.com/flutter/flutter/issues/new?template=01_activation.yml"
    >&2 echo
    rm -f -- "$DART_SDK_ZIP"
    rm -rf -- "$DART_SDK_PATH_TEMP"
    exit 1
  }
  rm -f -- "$DART_SDK_ZIP"

  if [ ! -d "$DART_SDK_PATH_TEMP/dart-sdk" ]; then
    >&2 echo "Dart SDK extraction failed: '$DART_SDK_PATH_TEMP/dart-sdk' not found."
    rm -rf -- "$DART_SDK_PATH_TEMP"
    exit 1
  fi

  # The unzip might have extracted LICENSE.dart_sdk_archive.md to the temp dir
  if [ -f "$DART_SDK_PATH_TEMP/LICENSE.dart_sdk_archive.md" ]; then
    mv "$DART_SDK_PATH_TEMP/LICENSE.dart_sdk_archive.md" "$FLUTTER_ROOT/bin/cache/LICENSE.dart_sdk_archive.md"
  fi

  $FIND "$DART_SDK_PATH_TEMP/dart-sdk" -type d -exec chmod 755 {} +
  $FIND "$DART_SDK_PATH_TEMP/dart-sdk" -type f $IS_USER_EXECUTABLE -exec chmod a+x,a+r {} +

  # Move old SDK to a temporary location in case it is still in use (e.g. by an IDE).
  if [ -d "$DART_SDK_PATH" ]; then
    rm -rf "$DART_SDK_PATH_OLD"
    mv "$DART_SDK_PATH" "$DART_SDK_PATH_OLD"
  fi

  # Move the extracted SDK to the final location
  mv "$DART_SDK_PATH_TEMP/dart-sdk" "$DART_SDK_PATH" || {
    >&2 echo "Failed to move Dart SDK to final destination."
    rm -rf -- "$DART_SDK_PATH_TEMP"
    exit 1
  }
  rm -rf -- "$DART_SDK_PATH_TEMP"

  if [ -n "$ORIGINAL_ENGINE_VERSION" ]; then
    write_fallback_stamps "$ORIGINAL_ENGINE_VERSION" "$ENGINE_VERSION"
  fi
  echo "$ENGINE_VERSION" > "$ENGINE_STAMP"

  # delete any temporary sdk path
  if [ -d "$DART_SDK_PATH_OLD" ]; then
    rm -rf "$DART_SDK_PATH_OLD"
  fi
fi
