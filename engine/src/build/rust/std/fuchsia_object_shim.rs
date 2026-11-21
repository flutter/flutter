// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Minimal `object` 0.39 shim for `library/backtrace/src/print/fuchsia.rs` when
// building `libstd` from source on Fuchsia without the `backtrace` DWARF
// symbolizer feature.
//
// Why this file exists:
// 1. Even with the `backtrace` Cargo feature disabled on `std`,
//    `library/std/src/lib.rs` includes `library/backtrace/src/print.rs`, which
//    unconditionally compiles `#[cfg(target_os = "fuchsia")] mod fuchsia;`.
//    That module imports `object::{NativeEndian, elf::NoteHeader32, pod::from_bytes}`
//    to parse ELF build-ID notes from loaded DSOs in memory.
// 2. In Chromium (`//build/rust/std/rules/BUILD.gn`), `gnrt gen --for-std`
//    compiles `object 0.39` from `library/vendor/` (packaged into Chromium's
//    Rust toolchain archive by `//tools/rust/package_rust.py`). Flutter instead
//    uses the CIPD `fuchsia/third_party/rust/src` package (which omits
//    `library/vendor/`) paired with Chromium's third-party crate repository at
//    `//third_party/rust/chromium_crates_io/vendor` (and `//third_party/fuchsia-sdk`
//    is a C/C++/FIDL SDK that does not ship Rust crates).
// 3. `//third_party/rust/chromium_crates_io/vendor/object-v0_40` cannot be
//    used directly here because `object 0.40` (rolled in
//    https://crrev.com/c/8771125) changed `NoteHeader32::n_type` from `U32<E>`
//    (`u32`) to `U32<E, NoteType>`, which fails to compile against
//    `library/backtrace/src/print/fuchsia.rs:203` (`expected u32, found NoteType`).
//    Providing the 3 items required by `print/fuchsia.rs` avoids that version
//    mismatch and avoids compiling the 7,800-line `object` crate into Fuchsia's
//    `libstd`.
#![no_std]

#[derive(Copy, Clone)]
pub struct NativeEndian;

#[derive(Copy, Clone)]
#[repr(C)]
pub struct U32<E>(u32, core::marker::PhantomData<E>);

impl<E> U32<E> {
  pub fn get(&self, _: E) -> u32 {
    self.0
  }
}

pub mod elf {
  use super::U32;

  #[derive(Copy, Clone)]
  #[repr(C)]
  pub struct NoteHeader32<E> {
    pub n_namesz: U32<E>,
    pub n_descsz: U32<E>,
    pub n_type: U32<E>,
  }
}

pub mod pod {
  use core::mem::{align_of, size_of};

  pub fn from_bytes<T: Copy>(bytes: &[u8]) -> Result<(&T, &[u8]), ()> {
    if bytes.len() < size_of::<T>() {
      return Err(());
    }
    if (bytes.as_ptr() as usize) % align_of::<T>() != 0 {
      return Err(());
    }
    let (head, tail) = bytes.split_at(size_of::<T>());
    let val = unsafe { &*(head.as_ptr() as *const T) };
    Ok((val, tail))
  }
}
