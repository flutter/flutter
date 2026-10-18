// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// flutter-rust-runner-version: 4

use std::{env, path::PathBuf};

fn main() {
    let manifest_dir = PathBuf::from(env::var_os("CARGO_MANIFEST_DIR").unwrap());
    // Cargo sets PROFILE to "debug" or "release"; the Flutter tool builds a
    // matching engine (JIT vs AOT-capable) under the same name so `cargo
    // build --release` links the engine that can actually run an AOT app.
    let profile = env::var("PROFILE").unwrap();
    let engine_dir = manifest_dir.join("../.dart_tool/flutter_rs/sdk/lib").join(&profile);
    let engine_library = engine_dir.join("libflutter_rust_engine.so");
    assert!(
        engine_library.is_file(),
        "Flutter Rust engine library is missing: {}. Run `flutter pub get` to install it.",
        engine_library.display()
    );
    println!("cargo:rerun-if-changed={}", engine_library.display());
    println!("cargo:rustc-link-search=native={}", engine_dir.display());
    println!("cargo:rustc-link-lib=dylib=flutter_rust_engine");
    // `$ORIGIN/libs` first so a bundle produced by `flutter build rust`
    // (engine and native plugin libraries copied into `<exe dir>/libs`; not
    // `lib/`, which plugins such as GStreamer wrappers treat as a bundled
    // third-party library directory) is
    // relocatable; the absolute engine path remains as the in-tree fallback.
    // --disable-new-dtags emits DT_RPATH rather than DT_RUNPATH, so the path
    // also applies to libraries the engine/Dart FFI dlopens by bare name.
    println!("cargo:rustc-link-arg=-Wl,--disable-new-dtags");
    println!("cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN/libs");
    println!("cargo:rustc-link-arg=-Wl,-rpath,{}", engine_dir.display());
    println!("cargo:rustc-link-arg=-Wl,--export-dynamic");
    println!("cargo::rustc-env=FLUTTER_RS_PROFILE={profile}");
}
