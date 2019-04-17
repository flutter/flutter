// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_BYTE_STREAM_WRAPPERS_H_
#define FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_BYTE_STREAM_WRAPPERS_H_

// Utility classes for interacting with a buffer of bytes as a stream, for use
// in message channel codecs.

#include <cstdint>
#include <cstring>
#include <iostream>
#include <vector>

namespace flutter {

// Wraps an array of bytes with utility methods for treating it as a readable
// stream.
class ByteBufferStreamReader {
 public:
  // Createa a reader reading from |bytes|, which must have a length of |size|.
  // |bytes| must remain valid for the lifetime of this object.
  explicit ByteBufferStreamReader(const uint8_t* bytes, size_t size)
      : bytes_(bytes), size_(size) {}

  // Reads and returns the next byte from the stream.
  uint8_t ReadByte() {
    if (location_ >= size_) {
      std::cerr << "Invalid read in StandardCodecByteStreamReader" << std::endl;
      return 0;
    }
    return bytes_[location_++];
  }

  // Reads the next |length| bytes from the stream into |buffer|. The caller
  // is responsible for ensuring that |buffer| is large enough.
  void ReadBytes(uint8_t* buffer, size_t length) {
    if (location_ + length > size_) {
      std::cerr << "Invalid read in StandardCodecByteStreamReader" << std::endl;
      return;
    }
    std::memcpy(buffer, &bytes_[location_], length);
    location_ += length;
  }

  // Advances the read cursor to the next multiple of |alignment| relative to
  // the start of the wrapped byte buffer, unless it is already aligned.
  void ReadAlignment(uint8_t alignment) {
    uint8_t mod = location_ % alignment;
    if (mod) {
      location_ += alignment - mod;
    }
  }

 private:
  // The buffer to read from.
  const uint8_t* bytes_;
  // The total size of the buffer.
  size_t size_;
  // The current read location.
  size_t location_ = 0;
};

// Wraps an array of bytes with utility methods for treating it as a writable
// stream.
class ByteBufferStreamWriter {
 public:
  // Createa a writter that writes into |buffer|.
  // |buffer| must remain valid for the lifetime of this object.
  explicit ByteBufferStreamWriter(std::vector<uint8_t>* buffer)
      : bytes_(buffer) {
    assert(buffer);
  }

  // Writes |byte| to the wrapped buffer.
  void WriteByte(uint8_t byte) { bytes_->push_back(byte); }

  // Writes the next |length| bytes from |bytes| into the wrapped buffer.
  // The caller is responsible for ensuring that |buffer| is large enough.
  void WriteBytes(const uint8_t* bytes, size_t length) {
    assert(length > 0);
    bytes_->insert(bytes_->end(), bytes, bytes + length);
  }

  // Writes 0s until the next multiple of |alignment| relative to
  // the start of the wrapped byte buffer, unless the write positition is
  // already aligned.
  void WriteAlignment(uint8_t alignment) {
    uint8_t mod = bytes_->size() % alignment;
    if (mod) {
      for (int i = 0; i < alignment - mod; ++i) {
        WriteByte(0);
      }
    }
  }

 private:
  // The buffer to write to.
  std::vector<uint8_t>* bytes_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_COMMON_CPP_CLIENT_WRAPPER_BYTE_STREAM_WRAPPERS_H_
