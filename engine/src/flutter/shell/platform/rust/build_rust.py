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
  args = parser.parse_args()

  manifest_path = Path(args.manifest_path).resolve()
  output_path = Path(args.output).resolve()
  cargo_target_dir = output_path.parent / "cargo-target"
  profile_dir = ("release" if os.environ.get("FLUTTER_RUNTIME_MODE") == "release" else "debug")
  artifact_dir = cargo_target_dir / (args.target or "") / profile_dir
  extension = "so" if args.crate_type == "cdylib" else "a"
  prefix = "" if extension == "so" and os.name == "nt" else "lib"
  artifact = artifact_dir / (prefix + args.package.replace("-", "_") + "." + extension)

  environment = os.environ.copy()
  environment["CARGO_TARGET_DIR"] = str(cargo_target_dir)

  command = [
      args.cargo,
      "build",
      "--locked",
      "--manifest-path",
      str(manifest_path),
      "--package",
      args.package,
  ]
  if args.target:
    command += ["--target", args.target]
    cargo_env_target = args.target.replace("-", "_").upper()
    if args.android_clang:
      environment[f"CC_{args.target.replace('-', '_')}"] = args.android_clang
      environment[f"CARGO_TARGET_{cargo_env_target}_LINKER"] = args.android_clang
    if args.android_clang_cxx:
      environment[f"CXX_{args.target.replace('-', '_')}"] = args.android_clang_cxx
    if args.android_ar:
      environment[f"AR_{args.target.replace('-', '_')}"] = args.android_ar
      environment[f"CARGO_TARGET_{cargo_env_target}_AR"] = args.android_ar

  subprocess.run(command, check=True, env=environment)

  output_path.parent.mkdir(parents=True, exist_ok=True)
  shutil.copy2(artifact, output_path)


if __name__ == "__main__":
  main()
