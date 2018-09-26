// Copyright 2018 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/base32.h"

#include <limits>

#include "flutter/fml/macros.h"

namespace fml {

static constexpr char kEncoding[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";

std::pair<bool, std::string> Base32Encode(StringView input) {
  if (input.empty()) {
    return {true, ""};
  }

  if (input.size() > std::numeric_limits<size_t>::max() / 8) {
    return {false, ""};
  }

  std::string output;
  const size_t encoded_length = (input.size() * 8 + 4) / 5;
  output.reserve(encoded_length);

  uint16_t bit_stream = (static_cast<uint8_t>(input[0]) << 8);
  size_t next_byte_index = 1;
  int free_bits = 8;

  while (free_bits < 16) {
    output.push_back(kEncoding[(bit_stream & 0xf800) >> 11]);
    bit_stream <<= 5;
    free_bits += 5;

    if (free_bits >= 8 && next_byte_index < input.size()) {
      free_bits -= 8;
      bit_stream += static_cast<uint8_t>(input[next_byte_index++]) << free_bits;
    }
  }

  return {true, output};
}

}  // namespace fml
