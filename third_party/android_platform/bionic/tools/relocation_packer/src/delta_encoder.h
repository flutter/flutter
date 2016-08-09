// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Delta encode and decode REL/RELA section of elf file.
//
// The encoded data format is sequence of elements of ElfAddr type (unsigned long):
//
// [00] relocation_count - the total count of relocations
// [01] initial r_offset - this is initial r_offset for the
//                         relocation table.
// followed by group structures:
// [02] group
// ...
// [nn] group

// the generalized format of the group is (! - always present ? - depends on group_flags):
// --------------
// ! group_size
// ! group_flags
// ? group_r_offset_delta when RELOCATION_GROUPED_BY_OFFSET_DELTA flag is set
// ? group_r_info when RELOCATION_GROUPED_BY_INFO flag is set
// ? group_r_addend_group_delta when RELOCATION_GROUP_HAS_ADDEND and RELOCATION_GROUPED_BY_ADDEND
//   flag is set
//
// The group description is followed by individual relocations.
// please note that there is a case when individual relocation
// section could be empty - that is if every field ends up grouped.
//
// The format for individual relocations section is:
// ? r_offset_delta - when RELOCATION_GROUPED_BY_OFFSET_DELTA is not set
// ? r_info - when RELOCATION_GROUPED_BY_INFO flag is not set
// ? r_addend_delta - RELOCATION_GROUP_HAS_ADDEND is set and RELOCATION_GROUPED_BY_ADDEND is not set
//
// For example lets pack the following relocations:
//
// Relocation section '.rela.dyn' at offset 0xbf58 contains 939 entries:
//     Offset             Info             Type               Symbol's Value  Symbol's Name + Addend
//     00000000000a2178  0000000000000403 R_AARCH64_RELATIVE                        177a8
//     00000000000a2180  0000000000000403 R_AARCH64_RELATIVE                        177cc
//     00000000000a2188  0000000000000403 R_AARCH64_RELATIVE                        177e0
//     00000000000a2190  0000000000000403 R_AARCH64_RELATIVE                        177f4
//     00000000000a2198  0000000000000403 R_AARCH64_RELATIVE                        17804
//     00000000000a21a0  0000000000000403 R_AARCH64_RELATIVE                        17818
//     00000000000a21a8  0000000000000403 R_AARCH64_RELATIVE                        1782c
//     00000000000a21b0  0000000000000403 R_AARCH64_RELATIVE                        17840
//     00000000000a21b8  0000000000000403 R_AARCH64_RELATIVE                        17854
//     00000000000a21c0  0000000000000403 R_AARCH64_RELATIVE                        17868
//     00000000000a21c8  0000000000000403 R_AARCH64_RELATIVE                        1787c
//     00000000000a21d0  0000000000000403 R_AARCH64_RELATIVE                        17890
//     00000000000a21d8  0000000000000403 R_AARCH64_RELATIVE                        178a4
//     00000000000a21e8  0000000000000403 R_AARCH64_RELATIVE                        178b8
//
// The header is going to be
// [00] 14                 <- count
// [01] 0x00000000000a2170 <- initial relocation (first relocation - delta,
//                            the delta is 8 in this case)
// -- starting the first and only group
// [03] 14                 <- group size
// [03] 0xb                <- flags RELOCATION_GROUP_HAS_ADDEND | RELOCATION_GROUPED_BY_OFFSET_DELTA
//                            | RELOCATION_GROUPED_BY_INFO
// [04] 8                  <- offset delta
// [05] 0x403              <- r_info
// -- end of group definition, starting list of r_addend deltas
// [06] 0x177a8
// [07] 0x24               = 177cc - 177a8
// [08] 0x14               = 177e0 - 177cc
// [09] 0x14               = 177f4 - 177e0
// [10] 0x10               = 17804 - 177f4
// [11] 0x14               = 17818 - 17804
// [12] 0x14               = 1782c - 17818
// [13] 0x14               = 17840 - 1782c
// [14] 0x14               = 17854 - 17840
// [15] 0x14               = 17868 - 17854
// [16] 0x14               = 1787c - 17868
// [17] 0x14               = 17890 - 1787c
// [18] 0x14               = 178a4 - 17890
// [19] 0x14               = 178b8 - 178a4
// -- the end.

// TODO (dimitry): consider using r_addend_group_delta in the way we use group offset delta, it can
//                 save us more bytes...

// The input ends when sum(group_size) == relocation_count

#ifndef TOOLS_RELOCATION_PACKER_SRC_DELTA_ENCODER_H_
#define TOOLS_RELOCATION_PACKER_SRC_DELTA_ENCODER_H_

#include <vector>

#include "elf.h"
#include "elf_traits.h"

namespace relocation_packer {

// A RelocationDeltaCodec packs vectors of relative relocations with
// addends into more compact forms, and unpacks them to reproduce the
// pre-packed data.
template <typename ELF>
class RelocationDeltaCodec {
 public:
  typedef typename ELF::Addr ElfAddr;
  typedef typename ELF::Rela ElfRela;

  // Encode relocations with addends into a more compact form.
  // |relocations| is a vector of relative relocation with addend structs.
  // |packed| is the vector of packed words into which relocations are packed.
  static void Encode(const std::vector<ElfRela>& relocations,
                     std::vector<ElfAddr>* packed);

  // Decode relative relocations with addends from their more compact form.
  // |packed| is the vector of packed relocations.
  // |relocations| is a vector of unpacked relative relocations.
  static void Decode(const std::vector<ElfAddr>& packed,
                     std::vector<ElfRela>* relocations);

 private:
  static void DetectGroup(const std::vector<ElfRela>& relocations,
                          size_t group_starts_with, ElfAddr previous_offset,
                          ElfAddr* group_size, ElfAddr* group_flags,
                          ElfAddr* group_offset_delta, ElfAddr* group_info,
                          ElfAddr* group_addend);

  static void DetectGroupFields(const ElfRela& reloc_one, const ElfRela& reloc_two,
                                ElfAddr current_offset_delta, ElfAddr* group_flags,
                                ElfAddr* group_offset_delta, ElfAddr* group_info,
                                ElfAddr* group_addend);
};

}  // namespace relocation_packer

#endif  // TOOLS_RELOCATION_PACKER_SRC_DELTA_ENCODER_H_
