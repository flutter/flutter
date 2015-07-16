// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sleb128.h"

#include <limits.h>
#include <stdint.h>
#include <vector>

#include "elf_traits.h"

namespace relocation_packer {

// Empty constructor and destructor to silence chromium-style.
Sleb128Encoder::Sleb128Encoder() { }
Sleb128Encoder::~Sleb128Encoder() { }

// Add a single value to the encoding.  Values are encoded with variable
// length.  The least significant 7 bits of each byte hold 7 bits of data,
// and the most significant bit is set on each byte except the last.  The
// value is sign extended up to a multiple of 7 bits (ensuring that the
// most significant bit is zero for a positive number and one for a
// negative number).
void Sleb128Encoder::Enqueue(ELF::Sxword value) {
  static const size_t size = CHAR_BIT * sizeof(value);

  bool more = true;
  const bool negative = value < 0;

  while (more) {
    uint8_t byte = value & 127;
    value >>= 7;

    // Sign extend if encoding a -ve value.
    if (negative)
      value |= -(static_cast<ELF::Sxword>(1) << (size - 7));

    // The sign bit of byte is second high order bit.
    const bool sign_bit = byte & 64;
    if ((value == 0 && !sign_bit) || (value == -1 && sign_bit))
      more = false;
    else
      byte |= 128;
    encoding_.push_back(byte);
  }
}

// Add a vector of values to the encoding.
void Sleb128Encoder::EnqueueAll(const std::vector<ELF::Sxword>& values) {
  for (size_t i = 0; i < values.size(); ++i)
    Enqueue(values[i]);
}

// Create a new decoder for the given encoded stream.
Sleb128Decoder::Sleb128Decoder(const std::vector<uint8_t>& encoding) {
  encoding_ = encoding;
  cursor_ = 0;
}

// Empty destructor to silence chromium-style.
Sleb128Decoder::~Sleb128Decoder() { }

// Decode and retrieve a single value from the encoding.  Consume bytes
// until one without its most significant bit is found, and re-form the
// value from the 7 bit fields of the bytes consumed.
ELF::Sxword Sleb128Decoder::Dequeue() {
  ELF::Sxword value = 0;
  static const size_t size = CHAR_BIT * sizeof(value);

  size_t shift = 0;
  uint8_t byte;

  // Loop until we reach a byte with its high order bit clear.
  do {
    byte = encoding_[cursor_++];
    value |= (static_cast<ELF::Sxword>(byte & 127) << shift);
    shift += 7;
  } while (byte & 128);

  // The sign bit is second high order bit of the final byte decoded.
  // Sign extend if value is -ve and we did not shift all of it.
  if (shift < size && (byte & 64))
    value |= -(static_cast<ELF::Sxword>(1) << shift);

  return value;
}

// Decode and retrieve all remaining values from the encoding.
void Sleb128Decoder::DequeueAll(std::vector<ELF::Sxword>* values) {
  while (cursor_ < encoding_.size())
    values->push_back(Dequeue());
}

}  // namespace relocation_packer
