// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Author: brianolson@google.com (Brian Olson)
//
// This file contains the implementation of classes GzipInputStream and
// GzipOutputStream.

#include "config.h"

#if HAVE_ZLIB
#include <google/protobuf/io/gzip_stream.h>

#include <google/protobuf/stubs/common.h>

namespace google {
namespace protobuf {
namespace io {

static const int kDefaultBufferSize = 65536;

GzipInputStream::GzipInputStream(
    ZeroCopyInputStream* sub_stream, Format format, int buffer_size)
    : format_(format), sub_stream_(sub_stream), zerror_(Z_OK) {
  zcontext_.zalloc = Z_NULL;
  zcontext_.zfree = Z_NULL;
  zcontext_.opaque = Z_NULL;
  zcontext_.total_out = 0;
  zcontext_.next_in = NULL;
  zcontext_.avail_in = 0;
  zcontext_.total_in = 0;
  zcontext_.msg = NULL;
  if (buffer_size == -1) {
    output_buffer_length_ = kDefaultBufferSize;
  } else {
    output_buffer_length_ = buffer_size;
  }
  output_buffer_ = operator new(output_buffer_length_);
  GOOGLE_CHECK(output_buffer_ != NULL);
  zcontext_.next_out = static_cast<Bytef*>(output_buffer_);
  zcontext_.avail_out = output_buffer_length_;
  output_position_ = output_buffer_;
}
GzipInputStream::~GzipInputStream() {
  operator delete(output_buffer_);
  zerror_ = inflateEnd(&zcontext_);
}

static inline int internalInflateInit2(
    z_stream* zcontext, GzipInputStream::Format format) {
  int windowBitsFormat = 0;
  switch (format) {
    case GzipInputStream::GZIP: windowBitsFormat = 16; break;
    case GzipInputStream::AUTO: windowBitsFormat = 32; break;
    case GzipInputStream::ZLIB: windowBitsFormat = 0; break;
  }
  return inflateInit2(zcontext, /* windowBits */15 | windowBitsFormat);
}

int GzipInputStream::Inflate(int flush) {
  if ((zerror_ == Z_OK) && (zcontext_.avail_out == 0)) {
    // previous inflate filled output buffer. don't change input params yet.
  } else if (zcontext_.avail_in == 0) {
    const void* in;
    int in_size;
    bool first = zcontext_.next_in == NULL;
    bool ok = sub_stream_->Next(&in, &in_size);
    if (!ok) {
      zcontext_.next_out = NULL;
      zcontext_.avail_out = 0;
      return Z_STREAM_END;
    }
    zcontext_.next_in = static_cast<Bytef*>(const_cast<void*>(in));
    zcontext_.avail_in = in_size;
    if (first) {
      int error = internalInflateInit2(&zcontext_, format_);
      if (error != Z_OK) {
        return error;
      }
    }
  }
  zcontext_.next_out = static_cast<Bytef*>(output_buffer_);
  zcontext_.avail_out = output_buffer_length_;
  output_position_ = output_buffer_;
  int error = inflate(&zcontext_, flush);
  return error;
}

void GzipInputStream::DoNextOutput(const void** data, int* size) {
  *data = output_position_;
  *size = ((uintptr_t)zcontext_.next_out) - ((uintptr_t)output_position_);
  output_position_ = zcontext_.next_out;
}

// implements ZeroCopyInputStream ----------------------------------
bool GzipInputStream::Next(const void** data, int* size) {
  bool ok = (zerror_ == Z_OK) || (zerror_ == Z_STREAM_END)
      || (zerror_ == Z_BUF_ERROR);
  if ((!ok) || (zcontext_.next_out == NULL)) {
    return false;
  }
  if (zcontext_.next_out != output_position_) {
    DoNextOutput(data, size);
    return true;
  }
  if (zerror_ == Z_STREAM_END) {
    if (zcontext_.next_out != NULL) {
      // sub_stream_ may have concatenated streams to follow
      zerror_ = inflateEnd(&zcontext_);
      if (zerror_ != Z_OK) {
        return false;
      }
      zerror_ = internalInflateInit2(&zcontext_, format_);
      if (zerror_ != Z_OK) {
        return false;
      }
    } else {
      *data = NULL;
      *size = 0;
      return false;
    }
  }
  zerror_ = Inflate(Z_NO_FLUSH);
  if ((zerror_ == Z_STREAM_END) && (zcontext_.next_out == NULL)) {
    // The underlying stream's Next returned false inside Inflate.
    return false;
  }
  ok = (zerror_ == Z_OK) || (zerror_ == Z_STREAM_END)
      || (zerror_ == Z_BUF_ERROR);
  if (!ok) {
    return false;
  }
  DoNextOutput(data, size);
  return true;
}
void GzipInputStream::BackUp(int count) {
  output_position_ = reinterpret_cast<void*>(
      reinterpret_cast<uintptr_t>(output_position_) - count);
}
bool GzipInputStream::Skip(int count) {
  const void* data;
  int size;
  bool ok = Next(&data, &size);
  while (ok && (size < count)) {
    count -= size;
    ok = Next(&data, &size);
  }
  if (size > count) {
    BackUp(size - count);
  }
  return ok;
}
int64 GzipInputStream::ByteCount() const {
  return zcontext_.total_out +
    (((uintptr_t)zcontext_.next_out) - ((uintptr_t)output_position_));
}

// =========================================================================

GzipOutputStream::Options::Options()
    : format(GZIP),
      buffer_size(kDefaultBufferSize),
      compression_level(Z_DEFAULT_COMPRESSION),
      compression_strategy(Z_DEFAULT_STRATEGY) {}

GzipOutputStream::GzipOutputStream(ZeroCopyOutputStream* sub_stream) {
  Init(sub_stream, Options());
}

GzipOutputStream::GzipOutputStream(ZeroCopyOutputStream* sub_stream,
                                   const Options& options) {
  Init(sub_stream, options);
}

void GzipOutputStream::Init(ZeroCopyOutputStream* sub_stream,
                            const Options& options) {
  sub_stream_ = sub_stream;
  sub_data_ = NULL;
  sub_data_size_ = 0;

  input_buffer_length_ = options.buffer_size;
  input_buffer_ = operator new(input_buffer_length_);
  GOOGLE_CHECK(input_buffer_ != NULL);

  zcontext_.zalloc = Z_NULL;
  zcontext_.zfree = Z_NULL;
  zcontext_.opaque = Z_NULL;
  zcontext_.next_out = NULL;
  zcontext_.avail_out = 0;
  zcontext_.total_out = 0;
  zcontext_.next_in = NULL;
  zcontext_.avail_in = 0;
  zcontext_.total_in = 0;
  zcontext_.msg = NULL;
  // default to GZIP format
  int windowBitsFormat = 16;
  if (options.format == ZLIB) {
    windowBitsFormat = 0;
  }
  zerror_ = deflateInit2(
      &zcontext_,
      options.compression_level,
      Z_DEFLATED,
      /* windowBits */15 | windowBitsFormat,
      /* memLevel (default) */8,
      options.compression_strategy);
}

GzipOutputStream::~GzipOutputStream() {
  Close();
  if (input_buffer_ != NULL) {
    operator delete(input_buffer_);
  }
}

// private
int GzipOutputStream::Deflate(int flush) {
  int error = Z_OK;
  do {
    if ((sub_data_ == NULL) || (zcontext_.avail_out == 0)) {
      bool ok = sub_stream_->Next(&sub_data_, &sub_data_size_);
      if (!ok) {
        sub_data_ = NULL;
        sub_data_size_ = 0;
        return Z_BUF_ERROR;
      }
      GOOGLE_CHECK_GT(sub_data_size_, 0);
      zcontext_.next_out = static_cast<Bytef*>(sub_data_);
      zcontext_.avail_out = sub_data_size_;
    }
    error = deflate(&zcontext_, flush);
  } while (error == Z_OK && zcontext_.avail_out == 0);
  if ((flush == Z_FULL_FLUSH) || (flush == Z_FINISH)) {
    // Notify lower layer of data.
    sub_stream_->BackUp(zcontext_.avail_out);
    // We don't own the buffer anymore.
    sub_data_ = NULL;
    sub_data_size_ = 0;
  }
  return error;
}

// implements ZeroCopyOutputStream ---------------------------------
bool GzipOutputStream::Next(void** data, int* size) {
  if ((zerror_ != Z_OK) && (zerror_ != Z_BUF_ERROR)) {
    return false;
  }
  if (zcontext_.avail_in != 0) {
    zerror_ = Deflate(Z_NO_FLUSH);
    if (zerror_ != Z_OK) {
      return false;
    }
  }
  if (zcontext_.avail_in == 0) {
    // all input was consumed. reset the buffer.
    zcontext_.next_in = static_cast<Bytef*>(input_buffer_);
    zcontext_.avail_in = input_buffer_length_;
    *data = input_buffer_;
    *size = input_buffer_length_;
  } else {
    // The loop in Deflate should consume all avail_in
    GOOGLE_LOG(DFATAL) << "Deflate left bytes unconsumed";
  }
  return true;
}
void GzipOutputStream::BackUp(int count) {
  GOOGLE_CHECK_GE(zcontext_.avail_in, count);
  zcontext_.avail_in -= count;
}
int64 GzipOutputStream::ByteCount() const {
  return zcontext_.total_in + zcontext_.avail_in;
}

bool GzipOutputStream::Flush() {
  zerror_ = Deflate(Z_FULL_FLUSH);
  // Return true if the flush succeeded or if it was a no-op.
  return  (zerror_ == Z_OK) ||
      (zerror_ == Z_BUF_ERROR && zcontext_.avail_in == 0 &&
       zcontext_.avail_out != 0);
}

bool GzipOutputStream::Close() {
  if ((zerror_ != Z_OK) && (zerror_ != Z_BUF_ERROR)) {
    return false;
  }
  do {
    zerror_ = Deflate(Z_FINISH);
  } while (zerror_ == Z_OK);
  zerror_ = deflateEnd(&zcontext_);
  bool ok = zerror_ == Z_OK;
  zerror_ = Z_STREAM_END;
  return ok;
}

}  // namespace io
}  // namespace protobuf
}  // namespace google

#endif  // HAVE_ZLIB
