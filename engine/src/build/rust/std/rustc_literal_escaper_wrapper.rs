// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#![no_std]

mod num {
  pub type NonZeroChar = core::num::NonZero<char>;
}

#[path = "../../../third_party/rust/chromium_crates_io/vendor/proc-macro2-v1/src/rustc_literal_escaper.rs"]
mod inner;
pub use inner::*;
