// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_ENCODABLE_VALUE_SERIALIZER_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_ENCODABLE_VALUE_SERIALIZER_H_

#include "byte_stream_wrappers.h"
#include "include/flutter/encodable_value.h"

namespace flutter {

// Encapsulates the logic for encoding/decoding EncodableValues to/from the
// standard codec binary representation.
class StandardCodecSerializer {
 public:
  StandardCodecSerializer();
  ~StandardCodecSerializer();

  // Prevent copying.
  StandardCodecSerializer(StandardCodecSerializer const&) = delete;
  StandardCodecSerializer& operator=(StandardCodecSerializer const&) = delete;

  // Reads and returns the next value from |stream|.
  EncodableValue ReadValue(ByteBufferStreamReader* stream) const;

  // Writes the encoding of |value| to |stream|.
  void WriteValue(const EncodableValue& value,
                  ByteBufferStreamWriter* stream) const;

 protected:
  // Reads the variable-length size from the current position in |stream|.
  uint32_t ReadSize(ByteBufferStreamReader* stream) const;

  // Writes the variable-length size encoding to |stream|.
  void WriteSize(uint32_t size, ByteBufferStreamWriter* stream) const;

  // Reads a fixed-type list whose values are of type T from the current
  // position in |stream|, and returns it as the corresponding EncodableValue.
  // |T| must correspond to one of the support list value types of
  // EncodableValue.
  template <typename T>
  EncodableValue ReadVector(ByteBufferStreamReader* stream) const;

  // Writes |vector| to |stream| as a fixed-type list. |T| must correspond to
  // one of the support list value types of EncodableValue.
  template <typename T>
  void WriteVector(const std::vector<T> vector,
                   ByteBufferStreamWriter* stream) const;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_ENCODABLE_VALUE_SERIALIZER_H_
