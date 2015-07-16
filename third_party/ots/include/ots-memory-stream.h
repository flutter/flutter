// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_MEMORY_STREAM_H_
#define OTS_MEMORY_STREAM_H_

#include <cstring>
#include <limits>

#include "opentype-sanitiser.h"

namespace ots {

class MemoryStream : public OTSStream {
 public:
  MemoryStream(void *ptr, size_t length)
      : ptr_(ptr), length_(length), off_(0) {
  }

  virtual bool WriteRaw(const void *data, size_t length) {
    if ((off_ + length > length_) ||
        (length > std::numeric_limits<size_t>::max() - off_)) {
      return false;
    }
    std::memcpy(static_cast<char*>(ptr_) + off_, data, length);
    off_ += length;
    return true;
  }

  virtual bool Seek(off_t position) {
    if (position < 0) return false;
    if (static_cast<size_t>(position) > length_) return false;
    off_ = position;
    return true;
  }

  virtual off_t Tell() const {
    return off_;
  }

 private:
  void* const ptr_;
  size_t length_;
  off_t off_;
};

class ExpandingMemoryStream : public OTSStream {
 public:
  ExpandingMemoryStream(size_t initial, size_t limit)
      : length_(initial), limit_(limit), off_(0) {
    ptr_ = new uint8_t[length_];
  }

  ~ExpandingMemoryStream() {
    delete[] static_cast<uint8_t*>(ptr_);
  }

  void* get() const {
    return ptr_;
  }

  bool WriteRaw(const void *data, size_t length) {
    if ((off_ + length > length_) ||
        (length > std::numeric_limits<size_t>::max() - off_)) {
      if (length_ == limit_)
        return false;
      size_t new_length = (length_ + 1) * 2;
      if (new_length < length_)
        return false;
      if (new_length > limit_)
        new_length = limit_;
      uint8_t* new_buf = new uint8_t[new_length];
      std::memcpy(new_buf, ptr_, length_);
      length_ = new_length;
      delete[] static_cast<uint8_t*>(ptr_);
      ptr_ = new_buf;
      return WriteRaw(data, length);
    }
    std::memcpy(static_cast<char*>(ptr_) + off_, data, length);
    off_ += length;
    return true;
  }

  bool Seek(off_t position) {
    if (position < 0) return false;
    if (static_cast<size_t>(position) > length_) return false;
    off_ = position;
    return true;
  }

  off_t Tell() const {
    return off_;
  }

 private:
  void* ptr_;
  size_t length_;
  const size_t limit_;
  off_t off_;
};

}  // namespace ots

#endif  // OTS_MEMORY_STREAM_H_
