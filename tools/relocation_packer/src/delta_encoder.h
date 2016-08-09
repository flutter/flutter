// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Delta encode and decode relative relocations with addends.
//
// Relative relocations are the bulk of dynamic relocations (the
// .rel.dyn or .rela.dyn sections) in libchrome.<version>.so, and the ELF
// standard representation of them is wasteful.  .rel.dyn contains
// relocations without addends, .rela.dyn relocations with addends.
//
// A relocation with an addend is 12 bytes on 32 bit platforms and 24 bytes
// on 64 bit plaforms.  It is split into offset, info, and addend fields.
// Offsets strictly increase, and each is commonly a few bytes different
// from its predecessor.  Addends are less well behaved.  The info field is
// constant.  Example, from 'readelf -x4 libchrome.<version>.so' 64 bit:
//
//   offset            info
//   80949303 00000000 03040000 00000000 ................
//   addend            offset
//   fc015b00 00000000 88949303 00000000 ..[.............
//   info              addend
//   03040000 00000000 24025b00 00000000 ........$.[.....
//   offset            info
//   90949303 00000000 03040000 00000000 ................
//   addend            offset
//   3c025b00 00000000 98949303 00000000 <.[.............
//   info              addend
//   03040000 00000000 50025b00 00000000 ........P.[.....
//
// The offset strictly increases, but the addend is unpredictable, so run
// length encoding will not work well with this data.  We can however pack
// with delta encoding.  The upper four bytes of the eight byte offset and
// addend are invariably zeroes.  The difference between adjacent offsets
// is almost always small, and between adjacent addends is often small.  And
// info is constant and can be eliminated.
//
// Delta encoding reduces the size of the data modestly, so that the first
// three relocations above can be represented as:
//
// initial offset    initial addend    offset delta      addend delta
// 00000000 03939480 00000000 005b01fc 00000000 00000008 00000000 00000028
// offset delta      addend delta      ...
// 00000000 00000008 00000000 0000009f
//
// The addend delta can be negative as well as positive, but overall the
// deltas have a much smaller range than the input data.  When encoded as
// signed LEB128 the total data reduction becomes useful.

#ifndef TOOLS_RELOCATION_PACKER_SRC_DELTA_ENCODER_H_
#define TOOLS_RELOCATION_PACKER_SRC_DELTA_ENCODER_H_

#include <vector>

#include "elf.h"
#include "elf_traits.h"

namespace relocation_packer {

// A RelocationDeltaCodec packs vectors of relative relocations with
// addends into more compact forms, and unpacks them to reproduce the
// pre-packed data.
class RelocationDeltaCodec {
 public:
  // Encode relative relocations with addends into a more compact form.
  // |relocations| is a vector of relative relocation with addend structs.
  // |packed| is the vector of packed words into which relocations are packed.
  static void Encode(const std::vector<ELF::Rela>& relocations,
                     std::vector<ELF::Sxword>* packed);

  // Decode relative relocations with addends from their more compact form.
  // |packed| is the vector of packed relocations.
  // |relocations| is a vector of unpacked relative relocations.
  static void Decode(const std::vector<ELF::Sxword>& packed,
                     std::vector<ELF::Rela>* relocations);
};

}  // namespace relocation_packer

#endif  // TOOLS_RELOCATION_PACKER_SRC_DELTA_ENCODER_H_
