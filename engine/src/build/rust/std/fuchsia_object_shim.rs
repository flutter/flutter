// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Minimal `object` crate shim for `library/backtrace/src/print/fuchsia.rs`
// when building `libstd` without the full `backtrace` DWARF symbolizer.
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
