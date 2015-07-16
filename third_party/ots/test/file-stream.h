// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef OTS_FILE_STREAM_H_
#define OTS_FILE_STREAM_H_

#include "opentype-sanitiser.h"

namespace ots {

// An OTSStream implementation for testing.
class FILEStream : public OTSStream {
 public:
  explicit FILEStream(FILE *stream)
      : file_(stream), position_(0) {
  }

  ~FILEStream() {
    if (file_)
      fclose(file_);
  }

  bool WriteRaw(const void *data, size_t length) {
    if (!file_ || ::fwrite(data, length, 1, file_) == 1) {
      position_ += length;
      return true;
    }
    return false;
  }

  bool Seek(off_t position) {
#if defined(_WIN32)
    if (!file_ || !::_fseeki64(file_, position, SEEK_SET)) {
      position_ = position;
      return true;
    }
#else
    if (!file_ || !::fseeko(file_, position, SEEK_SET)) {
      position_ = position;
      return true;
    }
#endif  // defined(_WIN32)
    return false;
  }

  off_t Tell() const {
    return position_;
  }

 private:
  FILE * const file_;
  off_t position_;
};

}  // namespace ots

#endif  // OTS_FILE_STREAM_H_
