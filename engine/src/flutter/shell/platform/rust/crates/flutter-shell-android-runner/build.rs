// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Mirrors packages/flutter_tools/templates/rust_shell/runner-rs/build.rs.tmpl:
// Android has no separate host executable for GN's C++ toolchain to link
// the engine into, so this cdylib dynamically links against a GN-built
// `libflutter_rust_engine.so` instead, the same way a generated app's
// `runner-rs` binary links against the SDK-distributed one on Linux.

use std::{env, path::PathBuf};

fn main() {
    if env::var("CARGO_CFG_TARGET_OS").as_deref() != Ok("android") {
        return;
    }

    let engine_dir = PathBuf::from(
        env::var_os("FLUTTER_RUST_ENGINE_DIR")
            .expect("FLUTTER_RUST_ENGINE_DIR must point at the directory containing libflutter_rust_engine.so (set by the flutter_shell_android_runner_rust GN action)"),
    );
    let engine_library = engine_dir.join("libflutter_rust_engine.so");
    assert!(
        engine_library.is_file(),
        "Android flutter_rust_engine library is missing: {}. Build \
         //flutter/shell/platform/rust:flutter_rust_engine for this ABI first.",
        engine_library.display()
    );
    println!("cargo:rerun-if-changed={}", engine_library.display());
    println!("cargo:rerun-if-env-changed=FLUTTER_RUST_ENGINE_DIR");
    println!("cargo:rustc-link-search=native={}", engine_dir.display());
    println!("cargo:rustc-link-lib=dylib=flutter_rust_engine");
    // Unlike the desktop template, an absolute build-time path is useless
    // here: the engine .so ships inside the same APK jniLibs/<abi>/
    // directory and is extracted to a device-specific runtime path. $ORIGIN
    // tells the dynamic linker to resolve the dependency relative to
    // wherever this cdylib itself ends up loaded from.
    println!("cargo:rustc-link-arg=-Wl,-rpath,$ORIGIN");
}
