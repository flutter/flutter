// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "packer.h"

#include <vector>

#include "debug.h"
#include "delta_encoder.h"
#include "elf_traits.h"
#include "leb128.h"
#include "run_length_encoder.h"
#include "sleb128.h"

namespace relocation_packer {

// Pack relative relocations into a run-length encoded packed
// representation.
void RelocationPacker::PackRelativeRelocations(
    const std::vector<ELF::Rel>& relocations,
    std::vector<uint8_t>* packed) {
  // Run-length encode.
  std::vector<ELF::Xword> packed_words;
  RelocationRunLengthCodec codec;
  codec.Encode(relocations, &packed_words);

  // If insufficient data to run-length encode, do nothing.
  if (packed_words.empty())
    return;

  // LEB128 encode, with "APR1" prefix.
  Leb128Encoder encoder;
  encoder.Enqueue('A');
  encoder.Enqueue('P');
  encoder.Enqueue('R');
  encoder.Enqueue('1');
  encoder.EnqueueAll(packed_words);

  encoder.GetEncoding(packed);

  // Pad packed to a whole number of words.  This padding will decode as
  // LEB128 zeroes.  Run-length decoding ignores it because encoding
  // embeds the pairs count in the stream itself.
  while (packed->size() % sizeof(ELF::Word))
    packed->push_back(0);
}

// Unpack relative relocations from a run-length encoded packed
// representation.
void RelocationPacker::UnpackRelativeRelocations(
    const std::vector<uint8_t>& packed,
    std::vector<ELF::Rel>* relocations) {
  // LEB128 decode, after checking and stripping "APR1" prefix.
  std::vector<ELF::Xword> packed_words;
  Leb128Decoder decoder(packed);
  CHECK(decoder.Dequeue() == 'A' &&
        decoder.Dequeue() == 'P' &&
        decoder.Dequeue() == 'R' &&
        decoder.Dequeue() == '1');
  decoder.DequeueAll(&packed_words);

  // Run-length decode.
  RelocationRunLengthCodec codec;
  codec.Decode(packed_words, relocations);
}

// Pack relative relocations with addends into a delta encoded packed
// representation.
void RelocationPacker::PackRelativeRelocations(
    const std::vector<ELF::Rela>& relocations,
    std::vector<uint8_t>* packed) {
  // Delta encode.
  std::vector<ELF::Sxword> packed_words;
  RelocationDeltaCodec codec;
  codec.Encode(relocations, &packed_words);

  // If insufficient data to delta encode, do nothing.
  if (packed_words.empty())
    return;

  // Signed LEB128 encode, with "APA1" prefix.  ASCII does not encode as
  // itself under signed LEB128, so we have to treat it specially.
  Sleb128Encoder encoder;
  encoder.EnqueueAll(packed_words);
  std::vector<uint8_t> encoded;
  encoder.GetEncoding(&encoded);

  packed->push_back('A');
  packed->push_back('P');
  packed->push_back('A');
  packed->push_back('1');
  packed->insert(packed->end(), encoded.begin(), encoded.end());

  // Pad packed to a whole number of words.  This padding will decode as
  // signed LEB128 zeroes.  Delta decoding ignores it because encoding
  // embeds the pairs count in the stream itself.
  while (packed->size() % sizeof(ELF::Word))
    packed->push_back(0);
}

// Unpack relative relocations with addends from a delta encoded
// packed representation.
void RelocationPacker::UnpackRelativeRelocations(
    const std::vector<uint8_t>& packed,
    std::vector<ELF::Rela>* relocations) {
  // Check "APA1" prefix.
  CHECK(packed.at(0) == 'A' &&
        packed.at(1) == 'P' &&
        packed.at(2) == 'A' &&
        packed.at(3) == '1');

  // Signed LEB128 decode, after stripping "APA1" prefix.
  std::vector<ELF::Sxword> packed_words;
  std::vector<uint8_t> stripped(packed.begin() + 4, packed.end());
  Sleb128Decoder decoder(stripped);
  decoder.DequeueAll(&packed_words);

  // Delta decode.
  RelocationDeltaCodec codec;
  codec.Decode(packed_words, relocations);
}

}  // namespace relocation_packer
