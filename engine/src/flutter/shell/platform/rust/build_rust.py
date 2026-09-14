#!/usr/bin/env python3
# Copyright 2026 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Builds a Rust static library for consumption by a GN target."""

import argparse
import os
from pathlib import Path
import shutil
import subprocess


def main() -> None:
  parser = argparse.ArgumentParser()
  parser.add_argument("--cargo", default="cargo")
  parser.add_argument("--manifest-path", required=True)
  parser.add_argument("--package", required=True)
  parser.add_argument("--output", required=True)
  # Rust target triple, e.g. "aarch64-linux-android". Host compilation is
  # used when omitted, matching every non-Android caller of this script.
  parser.add_argument("--target")
  # "staticlib" (default) yields a "lib<pkg>.a" the C++/GN link step
  # consumes; "cdylib" yields a "lib<pkg>.so", which is what Android needs
  # since the OS loads the shell's crate directly rather than linking it
  # into a GN-built executable.
  parser.add_argument("--crate-type", default="staticlib", choices=["staticlib", "cdylib"])
  # Path to the NDK-bundled, API-level-versioned clang driver (e.g.
  # ".../aarch64-linux-android24-clang") used as both the C/C++ compiler for
  # build-time cc-rs dependencies and the final Rust linker driver. Required
  # together with --target for Android cross-compiles.
  parser.add_argument("--android-clang")
  parser.add_argument("--android-clang-cxx")
  parser.add_argument("--android-ar")
  # Overrides where Cargo's own scratch directory lives. Needed for Android:
  # --output there sits inside a directory (jniLibs/<abi>/) that Gradle scans
  # wholesale for native libraries, so Cargo's build-script/host artifacts
  # (proc-macro .so files, intermediate objects, etc.) must not be nested
  # underneath it or they get packaged into the APK too.
  parser.add_argument("--cargo-target-dir")
  # Forwarded to the build as FLUTTER_RUST_ENGINE_DIR, read by
  # flutter-shell-android-runner's build.rs to dynamically link against a
  # GN-built libflutter_rust_engine.so (Android has no C++-owned executable
  # to link that archive into instead).
  parser.add_argument("--engine-dir")
  args = parser.parse_args()

  manifest_path = Path(args.manifest_path).resolve()
  output_path = Path(args.output).resolve()
  cargo_target_dir = (
      Path(args.cargo_target_dir).resolve() if args.cargo_target_dir else output_path.parent /
      "cargo-target"
  )
  profile_dir = os.environ.get("FLUTTER_RUNTIME_MODE", "debug")
  cargo_profile_dir = "release" if profile_dir in ("profile", "release") else "debug"
  artifact_dir = cargo_target_dir / (args.target or "") / cargo_profile_dir
  extension = "so" if args.crate_type == "cdylib" else "a"
  prefix = "" if extension == "so" and os.name == "nt" else "lib"
  artifact = artifact_dir / (prefix + args.package.replace("-", "_") + "." + extension)

  environment = os.environ.copy()
  environment["CARGO_TARGET_DIR"] = str(cargo_target_dir)
  if args.engine_dir:
    environment["FLUTTER_RUST_ENGINE_DIR"] = str(Path(args.engine_dir).resolve())

  command = [
      args.cargo,
      "build",
      "--locked",
      "--manifest-path",
      str(manifest_path),
      "--package",
      args.package,
  ]
  if profile_dir in ("profile", "release"):
    command.append("--release")
  if args.target:
    command += ["--target", args.target]
    cargo_env_target = args.target.replace("-", "_").upper()
    # Cargo runs dependency build scripts (e.g. android-activity's, which
    # shells out to cc-rs) with the crate's own directory as the working
    # directory, not the directory this script was invoked from. A relative
    # NDK path resolves fine for the linker driver itself but breaks inside
    # those build scripts, so resolve to an absolute path here regardless of
    # what the caller passed in.
    if args.android_clang:
      android_clang = str(Path(args.android_clang).resolve())
      environment[f"CC_{args.target.replace('-', '_')}"] = android_clang
      environment[f"CARGO_TARGET_{cargo_env_target}_LINKER"] = android_clang
    if args.android_clang_cxx:
      environment[f"CXX_{args.target.replace('-', '_')}"] = str(
          Path(args.android_clang_cxx).resolve()
      )
    if args.android_ar:
      android_ar = str(Path(args.android_ar).resolve())
      environment[f"AR_{args.target.replace('-', '_')}"] = android_ar
      environment[f"CARGO_TARGET_{cargo_env_target}_AR"] = android_ar

  subprocess.run(command, check=True, env=environment)

  output_path.parent.mkdir(parents=True, exist_ok=True)
  shutil.copy2(artifact, output_path)


if __name__ == "__main__":
  main()
