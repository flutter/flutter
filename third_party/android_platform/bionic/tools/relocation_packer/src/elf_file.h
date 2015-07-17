// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ELF shared object file updates handler.
//
// Provides functions to pack relocations in the .rel.dyn or .rela.dyn
// sections, and unpack to return the file to its pre-packed state.
//
// SetPadding() causes PackRelocations() to pad .rel.dyn or .rela.dyn with
// NONE-type entries rather than cutting a hole out of the shared object
// file.  This keeps all load addresses and offsets constant, and enables
// easier debugging and testing.
//
// A packed shared object file is shorter than its non-packed original.
// Unpacking a packed file restores the file to its non-packed state.

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
template <typename ELF>
class ElfFile {
 public:
  explicit ElfFile(int fd)
      : fd_(fd), is_padding_relocations_(false), elf_(NULL),
        relocations_section_(NULL), dynamic_section_(NULL),
        relocations_type_(NONE), has_android_relocations_(false) {}
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
  enum relocations_type_t {
    NONE = 0, REL, RELA
  };

  // Load a new ElfFile from a filedescriptor.  If flushing, the file must
  // be open for read/write.  Returns true on successful ELF file load.
  // |fd| is an open file descriptor for the shared object.
  bool Load();

  // Templated packer, helper for PackRelocations().  Rel type is one of
  // ELF::Rel or ELF::Rela.
  bool PackTypedRelocations(std::vector<typename ELF::Rela>* relocations);

  // Templated unpacker, helper for UnpackRelocations().  Rel type is one of
  // ELF::Rel or ELF::Rela.
  bool UnpackTypedRelocations(const std::vector<uint8_t>& packed);

  // Write ELF file changes.
  void Flush();

  void AdjustRelativeRelocationTargets(typename ELF::Off hole_start,
                                       ssize_t hole_size,
                                       std::vector<typename ELF::Rela>* relocations);

  static void ResizeSection(Elf* elf, Elf_Scn* section, size_t new_size,
                            typename ELF::Word new_sh_type, relocations_type_t relocations_type);

  static void AdjustDynamicSectionForHole(Elf_Scn* dynamic_section,
                                          typename ELF::Off hole_start,
                                          ssize_t hole_size,
                                          relocations_type_t relocations_type);

  static void ConvertRelArrayToRelaVector(const typename ELF::Rel* rel_array, size_t rel_array_size,
                                          std::vector<typename ELF::Rela>* rela_vector);

  static void ConvertRelaVectorToRelVector(const std::vector<typename ELF::Rela>& rela_vector,
                                           std::vector<typename ELF::Rel>* rel_vector);


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

  // Relocation type found, assigned by Load().
  relocations_type_t relocations_type_;

  // Elf-file has android relocations section
  bool has_android_relocations_;
};

}  // namespace relocation_packer

#endif  // TOOLS_RELOCATION_PACKER_SRC_ELF_FILE_H_
