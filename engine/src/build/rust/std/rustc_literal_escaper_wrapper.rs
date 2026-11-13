// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Standalone crate-root wrapper for `rustc_literal_escaper` (required when
// compiling `library/proc_macro` from source on the host toolchain).
//
// Why this file exists:
// 1. In Rust 1.95+, `library/proc_macro/Cargo.toml` depends on the crates.io
//    package `rustc-literal-escaper`.
// 2. In Chromium (`//build/rust/std/rules/BUILD.gn`), `gnrt gen --for-std`
//    compiles `rustc-literal-escaper` from `library/vendor/` (bundled into
//    Chromium's Rust toolchain archive by `//tools/rust/package_rust.py`).
//    Flutter instead uses the CIPD `fuchsia/third_party/rust/src` package
//    (which omits `library/vendor/`) paired with Chromium's third-party crate
//    repository at `//third_party/rust/chromium_crates_io/vendor`.
// 3. Rather than making a duplicate copy of `rustc-literal-escaper` in the
//    tree, this wrapper references the upstream source file that is already
//    vendored in-tree at
//    `//third_party/rust/chromium_crates_io/vendor/proc-macro2-v1/src/rustc_literal_escaper.rs`
//    via `#[path = ...]`. Because `proc-macro2` vendors that file as an
//    internal submodule (without `#![no_std]` and importing
//    `crate::num::NonZeroChar`), this wrapper supplies `#![no_std]` and the
//    `num::NonZeroChar` type alias so `rustc` can compile it as a standalone
//    crate.
#![no_std]

mod num {
  pub type NonZeroChar = core::num::NonZero<char>;
}

#[path = "../../../third_party/rust/chromium_crates_io/vendor/proc-macro2-v1/src/rustc_literal_escaper.rs"]
mod inner;
pub use inner::*;
