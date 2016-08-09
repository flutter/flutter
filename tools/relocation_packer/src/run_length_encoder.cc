// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "run_length_encoder.h"

#include <vector>

#include "debug.h"
#include "elf_traits.h"

namespace relocation_packer {

namespace {

// Generate a vector of deltas between the r_offset fields of adjacent
// relative relocations.
void GetDeltas(const std::vector<ELF::Rel>& relocations,
               std::vector<ELF::Addr>* deltas) {
  CHECK(relocations.size() >= 2);

  for (size_t i = 0; i < relocations.size() - 1; ++i) {
    const ELF::Rel* first = &relocations[i];
    CHECK(ELF_R_TYPE(first->r_info) == ELF::kRelativeRelocationCode);

    const ELF::Rel* second = &relocations[i + 1];
    CHECK(ELF_R_TYPE(second->r_info) == ELF::kRelativeRelocationCode);

    // Requires that offsets are 'strictly increasing'.  The packing
    // algorithm fails if this does not hold.
    CHECK(second->r_offset > first->r_offset);
    deltas->push_back(second->r_offset - first->r_offset);
  }
}

// Condense a set of r_offset deltas into a run-length encoded packing.
// Represented as count-delta pairs, where count is the run length and
// delta the common difference between adjacent r_offsets.
void Condense(const std::vector<ELF::Addr>& deltas,
              std::vector<ELF::Xword>* packed) {
  CHECK(!deltas.empty());
  size_t count = 0;
  ELF::Addr current = deltas[0];

  // Identify spans of identically valued deltas.
  for (size_t i = 0; i < deltas.size(); ++i) {
    const ELF::Addr delta = deltas[i];
    if (delta == current) {
      count++;
    } else {
      // We reached the end of a span of identically valued deltas.
      packed->push_back(count);
      packed->push_back(current);
      current = delta;
      count = 1;
    }
  }

  // Write the final span.
  packed->push_back(count);
  packed->push_back(current);
}

// Uncondense a set of r_offset deltas from a run-length encoded packing.
// The initial address for uncondensing, the start index for the first
// condensed slot in packed, and the count of pairs are provided.
void Uncondense(ELF::Addr addr,
                const std::vector<ELF::Xword>& packed,
                size_t start_index,
                size_t end_index,
                std::vector<ELF::Rel>* relocations) {
  // The first relocation is just one created from the initial address.
  ELF::Rel initial;
  initial.r_offset = addr;
  initial.r_info = ELF_R_INFO(0, ELF::kRelativeRelocationCode);
  relocations->push_back(initial);

  // Read each count and delta pair, beginning at the start index and
  // finishing at the end index.
  for (size_t i = start_index; i < end_index; i += 2) {
    size_t count = packed[i];
    const ELF::Addr delta = packed[i + 1];
    CHECK(count > 0 && delta > 0);

    // Generate relocations for this count and delta pair.
    while (count) {
      addr += delta;
      ELF::Rel relocation;
      relocation.r_offset = addr;
      relocation.r_info = ELF_R_INFO(0, ELF::kRelativeRelocationCode);
      relocations->push_back(relocation);
      count--;
    }
  }
}

}  // namespace

// Encode relative relocations into a run-length encoded (packed)
// representation.
void RelocationRunLengthCodec::Encode(const std::vector<ELF::Rel>& relocations,
                                      std::vector<ELF::Xword>* packed) {
  // If we have zero or one relocation only then there is no packing
  // possible; a run-length encoding needs a run.
  if (relocations.size() < 2)
    return;

  std::vector<ELF::Addr> deltas;
  GetDeltas(relocations, &deltas);

  // Reserve space for the element count.
  packed->push_back(0);

  // Initialize the packed data with the first offset, then follow up with
  // the condensed deltas vector.
  packed->push_back(relocations[0].r_offset);
  Condense(deltas, packed);

  // Fill in the packed pair count.
  packed->at(0) = (packed->size() - 2) >> 1;
}

// Decode relative relocations from a run-length encoded (packed)
// representation.
void RelocationRunLengthCodec::Decode(const std::vector<ELF::Xword>& packed,
                                      std::vector<ELF::Rel>* relocations) {
  // We need at least one packed pair after the packed pair count and start
  // address to be able to unpack.
  if (packed.size() < 4)
    return;

  // Ensure that the packed data offers enough pairs.  There may be zero
  // padding on it that we ignore.
  CHECK(packed[0] <= (packed.size() - 2) >> 1);

  // The first packed vector element is the pairs count and the second the
  // initial address.  Start uncondensing pairs at the third, and finish
  // at the end of the pairs data.
  const size_t pairs_count = packed[0];
  const ELF::Addr addr = packed[1];
  Uncondense(addr, packed, 2, 2 + (pairs_count << 1), relocations);
}

}  // namespace relocation_packer
