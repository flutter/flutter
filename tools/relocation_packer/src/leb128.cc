// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "leb128.h"

#include <stdint.h>
#include <vector>

#include "elf_traits.h"

namespace relocation_packer {

// Empty constructor and destructor to silence chromium-style.
Leb128Encoder::Leb128Encoder() { }
Leb128Encoder::~Leb128Encoder() { }

// Add a single value to the encoding.  Values are encoded with variable
// length.  The least significant 7 bits of each byte hold 7 bits of data,
// and the most significant bit is set on each byte except the last.
void Leb128Encoder::Enqueue(ELF::Xword value) {
  do {
    const uint8_t byte = value & 127;
    value >>= 7;
    encoding_.push_back((value ? 128 : 0) | byte);
  } while (value);
}

// Add a vector of values to the encoding.
void Leb128Encoder::EnqueueAll(const std::vector<ELF::Xword>& values) {
  for (size_t i = 0; i < values.size(); ++i)
    Enqueue(values[i]);
}

// Create a new decoder for the given encoded stream.
Leb128Decoder::Leb128Decoder(const std::vector<uint8_t>& encoding) {
  encoding_ = encoding;
  cursor_ = 0;
}

// Empty destructor to silence chromium-style.
Leb128Decoder::~Leb128Decoder() { }

// Decode and retrieve a single value from the encoding.  Read forwards until
// a byte without its most significant bit is found, then read the 7 bit
// fields of the bytes spanned to re-form the value.
ELF::Xword Leb128Decoder::Dequeue() {
  ELF::Xword value = 0;

  size_t shift = 0;
  uint8_t byte;

  // Loop until we reach a byte with its high order bit clear.
  do {
    byte = encoding_[cursor_++];
    value |= static_cast<ELF::Xword>(byte & 127) << shift;
    shift += 7;
  } while (byte & 128);

  return value;
}

// Decode and retrieve all remaining values from the encoding.
void Leb128Decoder::DequeueAll(std::vector<ELF::Xword>* values) {
  while (cursor_ < encoding_.size())
    values->push_back(Dequeue());
}

}  // namespace relocation_packer
