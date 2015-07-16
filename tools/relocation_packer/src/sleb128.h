// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// SLEB128 encoder and decoder for packed relative relocations.
//
// Delta encoded relative relocations consist of a large number
// of pairs signed integer values, many with small values.  Encoding these
// as signed LEB128 saves space.
//
// For more on LEB128 see http://en.wikipedia.org/wiki/LEB128.

#ifndef TOOLS_RELOCATION_PACKER_SRC_SLEB128_H_
#define TOOLS_RELOCATION_PACKER_SRC_SLEB128_H_

#include <stdint.h>
#include <unistd.h>
#include <vector>

#include "elf_traits.h"

namespace relocation_packer {

// Encode packed words as a signed LEB128 byte stream.
class Sleb128Encoder {
 public:
  // Explicit (but empty) constructor and destructor, for chromium-style.
  Sleb128Encoder();
  ~Sleb128Encoder();

  // Add a value to the encoding stream.
  // |value| is the signed int to add.
  void Enqueue(ELF::Sxword value);

  // Add a vector of values to the encoding stream.
  // |values| is the vector of signed ints to add.
  void EnqueueAll(const std::vector<ELF::Sxword>& values);

  // Retrieve the encoded representation of the values.
  // |encoding| is the returned vector of encoded data.
  void GetEncoding(std::vector<uint8_t>* encoding) { *encoding = encoding_; }

 private:
  // Growable vector holding the encoded LEB128 stream.
  std::vector<uint8_t> encoding_;
};

// Decode a LEB128 byte stream to produce packed words.
class Sleb128Decoder {
 public:
  // Create a new decoder for the given encoded stream.
  // |encoding| is the vector of encoded data.
  explicit Sleb128Decoder(const std::vector<uint8_t>& encoding);

  // Explicit (but empty) destructor, for chromium-style.
  ~Sleb128Decoder();

  // Retrieve the next value from the encoded stream.
  ELF::Sxword Dequeue();

  // Retrieve all remaining values from the encoded stream.
  // |values| is the vector of decoded data.
  void DequeueAll(std::vector<ELF::Sxword>* values);

 private:
  // Encoded LEB128 stream.
  std::vector<uint8_t> encoding_;

  // Cursor indicating the current stream retrieval point.
  size_t cursor_;
};

}  // namespace relocation_packer

#endif  // TOOLS_RELOCATION_PACKER_SRC_SLEB128_H_
