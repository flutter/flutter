#!/bin/sh
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# The Apple toolchains' compiler when their compiles may run on Flutter's RBE
# workers (build/bazel:apple_remote_compiles; toolchains/macos_toolchain.bzl):
# one tool for an action that executes either on the Mac that builds or on a
# Linux x64 worker, running the clang built for whichever it is -- the Mac's
# (buildtools/mac-<cpu>/clang) or the Linux one (buildtools/linux-x64/clang),
# the same LLVM revision, so that the objects are the same wherever they were
# compiled. The toolchain names both in the action's environment, as paths
# relative to the execution root the action runs in, per action kind (clang
# for C and assembly, clang++ for C++ and Objective-C). What GN's reclient
# build does with build/rbe/remote_wrapper.sh, which rewrites the compiler's
# path for the worker.
case "$(uname -s)" in
  Darwin)
    exec "${FLUTTER_CLANG_HOST:?apple_clang_wrapper.sh: FLUTTER_CLANG_HOST is not set}" "$@"
    ;;
  Linux)
    exec "${FLUTTER_CLANG_REMOTE:?apple_clang_wrapper.sh: FLUTTER_CLANG_REMOTE is not set}" "$@"
    ;;
  *)
    echo "apple_clang_wrapper.sh: no clang for $(uname -s); the Apple toolchains compile on a Mac or on a Linux x64 worker" >&2
    exit 1
    ;;
esac
