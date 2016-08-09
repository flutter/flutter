// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ELF shared object file updates handler.
//
// Provides functions to remove relative relocations from the .rel.dyn
// or .rela.dyn sections and pack into .android.rel.dyn or .android.rela.dyn,
// and unpack to return the file to its pre-packed state.
//
// Files to be packed or unpacked must include an existing .android.rel.dyn
// or android.rela.dyn section.  A standard libchrome.<version>.so will not
// contain this section, so the following can be used to add one:
//
//   echo -n 'NULL' >/tmp/small
//   if file libchrome.<version>.so | grep -q 'ELF 32'; then
//     arm-linux-androideabi-objcopy
//         --add-section .android.rel.dyn=/tmp/small
//         libchrome.<version>.so libchrome.<version>.so.packed
//   else
//     aarch64-linux-android-objcopy
//         --add-section .android.rela.dyn=/tmp/small
//         libchrome.<version>.so libchrome.<version>.so.packed
//   fi
//   rm /tmp/small
//
// To use, open the file and pass the file descriptor to the constructor,
// then pack or unpack as desired.  Packing or unpacking will flush the file
// descriptor on success.  Example:
//
//   int fd = open(..., O_RDWR);
//   ElfFile elf_file(fd);
//   bool status;
//   if (is_packing)
//     status = elf_file.PackRelocations();
//   else
//     status = elf_file.UnpackRelocations();
//   close(fd);
//
// SetPadding() causes PackRelocations() to pad .rel.dyn or .rela.dyn with
// NONE-type entries rather than cutting a hole out of the shared object
// file.  This keeps all load addresses and offsets constant, and enables
// easier debugging and testing.
//
// A packed shared object file has all of its relative relocations
// removed from .rel.dyn or .rela.dyn, and replaced as packed data in
// .android.rel.dyn or .android.rela.dyn respectively.  The resulting file
// is shorter than its non-packed original.
//
// Unpacking a packed file restores the file to its non-packed state, by
// expanding the packed data in .android.rel.dyn or .android.rela.dyn,
// combining the relative relocations with the data already in .rel.dyn
// or .rela.dyn, and then writing back the now expanded section.

#ifndef TOOLS_RELOCATION_PACKER_SRC_ELF_FILE_H_
#define TOOLS_RELOCATION_PACKER_SRC_ELF_FILE_H_

#include <string.h>
#include <vector>

#include "elf.h"
#include "libelf.h"
#include "packer.h"

namespace relocation_packer {

// An ElfFile reads shared objects, and shuttles relative relocations
// between .rel.dyn or .rela.dyn and .android.rel.dyn or .android.rela.dyn
// sections.
class ElfFile {
 public:
  explicit ElfFile(int fd)
      : fd_(fd), is_padding_relocations_(false), elf_(NULL),
        relocations_section_(NULL), dynamic_section_(NULL),
        android_relocations_section_(NULL), relocations_type_(NONE) {}
  ~ElfFile() {}

  // Set padding mode.  When padding, PackRelocations() will not shrink
  // the .rel.dyn or .rela.dyn section, but instead replace relative with
  // NONE-type entries.
  // |flag| is true to pad .rel.dyn or .rela.dyn, false to shrink it.
  inline void SetPadding(bool flag) { is_padding_relocations_ = flag; }

  // Transfer relative relocations from .rel.dyn or .rela.dyn to a packed
  // representation in .android.rel.dyn or .android.rela.dyn.  Returns true
  // on success.
  bool PackRelocations();

  // Transfer relative relocations from a packed representation in
  // .android.rel.dyn or .android.rela.dyn to .rel.dyn or .rela.dyn.  Returns
  // true on success.
  bool UnpackRelocations();

 private:
  // Load a new ElfFile from a filedescriptor.  If flushing, the file must
  // be open for read/write.  Returns true on successful ELF file load.
  // |fd| is an open file descriptor for the shared object.
  bool Load();

  // Templated packer, helper for PackRelocations().  Rel type is one of
  // ELF::Rel or ELF::Rela.
  template <typename Rel>
  bool PackTypedRelocations(const std::vector<Rel>& relocations);

  // Templated unpacker, helper for UnpackRelocations().  Rel type is one of
  // ELF::Rel or ELF::Rela.
  template <typename Rel>
  bool UnpackTypedRelocations(const std::vector<uint8_t>& packed);

  // Write ELF file changes.
  void Flush();

  // File descriptor opened on the shared object.
  int fd_;

  // If set, pad rather than shrink .rel.dyn or .rela.dyn.  Primarily for
  // debugging, allows packing to be checked without affecting load addresses.
  bool is_padding_relocations_;

  // Libelf handle, assigned by Load().
  Elf* elf_;

  // Sections that we manipulate, assigned by Load().
  Elf_Scn* relocations_section_;
  Elf_Scn* dynamic_section_;
  Elf_Scn* android_relocations_section_;

  // Relocation type found, assigned by Load().
  enum { NONE = 0, REL, RELA } relocations_type_;
};

}  // namespace relocation_packer

#endif  // TOOLS_RELOCATION_PACKER_SRC_ELF_FILE_H_
