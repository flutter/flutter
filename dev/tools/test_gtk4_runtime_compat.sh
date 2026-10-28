#!/usr/bin/env bash
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Convenience entry point for the GTK4 runtime compatibility validator. The
# Python implementation owns sysroot selection, isolated build directories,
# ELF checks, and optional container execution.

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
exec python3 "${script_dir}/../../engine/src/flutter/shell/platform/linux/testing/validate_gtk4_runtime_compat.py" "$@"
