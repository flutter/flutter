// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "delta_encoder.h"

#include <vector>

#include "debug.h"
#include "elf_traits.h"

namespace relocation_packer {

// Encode relative relocations with addends into a delta encoded (packed)
// representation.  Represented as simple r_offset and r_addend delta pairs,
// with an implicit neutral element at the start.
void RelocationDeltaCodec::Encode(const std::vector<ELF::Rela>& relocations,
                                  std::vector<ELF::Sxword>* packed) {
  // One relocation is sufficient for delta encoding.
  if (relocations.size() < 1)
    return;

  // Start with the element count, then append the delta pairs.
  packed->push_back(relocations.size());

  ELF::Addr offset = 0;
  ELF::Sxword addend = 0;

  for (size_t i = 0; i < relocations.size(); ++i) {
    const ELF::Rela* relocation = &relocations[i];
    CHECK(ELF_R_TYPE(relocation->r_info) == ELF::kRelativeRelocationCode);

    packed->push_back(relocation->r_offset - offset);
    offset = relocation->r_offset;
    packed->push_back(relocation->r_addend - addend);
    addend = relocation->r_addend;
  }
}

// Decode relative relocations with addends from a delta encoded (packed)
// representation.
void RelocationDeltaCodec::Decode(const std::vector<ELF::Sxword>& packed,
                                  std::vector<ELF::Rela>* relocations) {
  // We need at least one packed pair after the packed pair count to be
  // able to unpack.
  if (packed.size() < 3)
    return;

  // Ensure that the packed data offers enough pairs.  There may be zero
  // padding on it that we ignore.
  CHECK(static_cast<size_t>(packed[0]) <= (packed.size() - 1) >> 1);

  ELF::Addr offset = 0;
  ELF::Sxword addend = 0;

  // The first packed vector element is the pairs count.  Start uncondensing
  // pairs at the second, and finish at the end of the pairs data.
  const size_t pairs_count = packed[0];
  for (size_t i = 1; i < 1 + (pairs_count << 1); i += 2) {
    offset += packed[i];
    addend += packed[i + 1];

    // Generate a relocation for this offset and addend pair.
    ELF::Rela relocation;
    relocation.r_offset = offset;
    relocation.r_info = ELF_R_INFO(0, ELF::kRelativeRelocationCode);
    relocation.r_addend = addend;
    relocations->push_back(relocation);
  }
}

}  // namespace relocation_packer
