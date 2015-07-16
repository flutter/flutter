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

// Author: kenton@google.com (Kenton Varda)
//  Based on original Protocol Buffers design by
//  Sanjay Ghemawat, Jeff Dean, and others.

#include <google/protobuf/io/zero_copy_stream_impl_lite.h>
#include <google/protobuf/stubs/common.h>
#include <google/protobuf/stubs/stl_util.h>

#include <algorithm>

namespace google {
namespace protobuf {
namespace io {

namespace {

// Default block size for Copying{In,Out}putStreamAdaptor.
static const int kDefaultBlockSize = 8192;

}  // namespace

// ===================================================================

ArrayInputStream::ArrayInputStream(const void* data, int size,
                                   int block_size)
  : data_(reinterpret_cast<const uint8*>(data)),
    size_(size),
    block_size_(block_size > 0 ? block_size : size),
    position_(0),
    last_returned_size_(0) {
}

ArrayInputStream::~ArrayInputStream() {
}

bool ArrayInputStream::Next(const void** data, int* size) {
  if (position_ < size_) {
    last_returned_size_ = min(block_size_, size_ - position_);
    *data = data_ + position_;
    *size = last_returned_size_;
    position_ += last_returned_size_;
    return true;
  } else {
    // We're at the end of the array.
    last_returned_size_ = 0;   // Don't let caller back up.
    return false;
  }
}

void ArrayInputStream::BackUp(int count) {
  GOOGLE_CHECK_GT(last_returned_size_, 0)
      << "BackUp() can only be called after a successful Next().";
  GOOGLE_CHECK_LE(count, last_returned_size_);
  GOOGLE_CHECK_GE(count, 0);
  position_ -= count;
  last_returned_size_ = 0;  // Don't let caller back up further.
}

bool ArrayInputStream::Skip(int count) {
  GOOGLE_CHECK_GE(count, 0);
  last_returned_size_ = 0;   // Don't let caller back up.
  if (count > size_ - position_) {
    position_ = size_;
    return false;
  } else {
    position_ += count;
    return true;
  }
}

int64 ArrayInputStream::ByteCount() const {
  return position_;
}


// ===================================================================

ArrayOutputStream::ArrayOutputStream(void* data, int size, int block_size)
  : data_(reinterpret_cast<uint8*>(data)),
    size_(size),
    block_size_(block_size > 0 ? block_size : size),
    position_(0),
    last_returned_size_(0) {
}

ArrayOutputStream::~ArrayOutputStream() {
}

bool ArrayOutputStream::Next(void** data, int* size) {
  if (position_ < size_) {
    last_returned_size_ = min(block_size_, size_ - position_);
    *data = data_ + position_;
    *size = last_returned_size_;
    position_ += last_returned_size_;
    return true;
  } else {
    // We're at the end of the array.
    last_returned_size_ = 0;   // Don't let caller back up.
    return false;
  }
}

void ArrayOutputStream::BackUp(int count) {
  GOOGLE_CHECK_GT(last_returned_size_, 0)
      << "BackUp() can only be called after a successful Next().";
  GOOGLE_CHECK_LE(count, last_returned_size_);
  GOOGLE_CHECK_GE(count, 0);
  position_ -= count;
  last_returned_size_ = 0;  // Don't let caller back up further.
}

int64 ArrayOutputStream::ByteCount() const {
  return position_;
}

// ===================================================================

StringOutputStream::StringOutputStream(string* target)
  : target_(target) {
}

StringOutputStream::~StringOutputStream() {
}

bool StringOutputStream::Next(void** data, int* size) {
  int old_size = target_->size();

  // Grow the string.
  if (old_size < target_->capacity()) {
    // Resize the string to match its capacity, since we can get away
    // without a memory allocation this way.
    STLStringResizeUninitialized(target_, target_->capacity());
  } else {
    // Size has reached capacity, so double the size.  Also make sure
    // that the new size is at least kMinimumSize.
    STLStringResizeUninitialized(
      target_,
      max(old_size * 2,
          kMinimumSize + 0));  // "+ 0" works around GCC4 weirdness.
  }

  *data = string_as_array(target_) + old_size;
  *size = target_->size() - old_size;
  return true;
}

void StringOutputStream::BackUp(int count) {
  GOOGLE_CHECK_GE(count, 0);
  GOOGLE_CHECK_LE(count, target_->size());
  target_->resize(target_->size() - count);
}

int64 StringOutputStream::ByteCount() const {
  return target_->size();
}

// ===================================================================

CopyingInputStream::~CopyingInputStream() {}

int CopyingInputStream::Skip(int count) {
  char junk[4096];
  int skipped = 0;
  while (skipped < count) {
    int bytes = Read(junk, min(count - skipped,
                               implicit_cast<int>(sizeof(junk))));
    if (bytes <= 0) {
      // EOF or read error.
      return skipped;
    }
    skipped += bytes;
  }
  return skipped;
}

CopyingInputStreamAdaptor::CopyingInputStreamAdaptor(
    CopyingInputStream* copying_stream, int block_size)
  : copying_stream_(copying_stream),
    owns_copying_stream_(false),
    failed_(false),
    position_(0),
    buffer_size_(block_size > 0 ? block_size : kDefaultBlockSize),
    buffer_used_(0),
    backup_bytes_(0) {
}

CopyingInputStreamAdaptor::~CopyingInputStreamAdaptor() {
  if (owns_copying_stream_) {
    delete copying_stream_;
  }
}

bool CopyingInputStreamAdaptor::Next(const void** data, int* size) {
  if (failed_) {
    // Already failed on a previous read.
    return false;
  }

  AllocateBufferIfNeeded();

  if (backup_bytes_ > 0) {
    // We have data left over from a previous BackUp(), so just return that.
    *data = buffer_.get() + buffer_used_ - backup_bytes_;
    *size = backup_bytes_;
    backup_bytes_ = 0;
    return true;
  }

  // Read new data into the buffer.
  buffer_used_ = copying_stream_->Read(buffer_.get(), buffer_size_);
  if (buffer_used_ <= 0) {
    // EOF or read error.  We don't need the buffer anymore.
    if (buffer_used_ < 0) {
      // Read error (not EOF).
      failed_ = true;
    }
    FreeBuffer();
    return false;
  }
  position_ += buffer_used_;

  *size = buffer_used_;
  *data = buffer_.get();
  return true;
}

void CopyingInputStreamAdaptor::BackUp(int count) {
  GOOGLE_CHECK(backup_bytes_ == 0 && buffer_.get() != NULL)
    << " BackUp() can only be called after Next().";
  GOOGLE_CHECK_LE(count, buffer_used_)
    << " Can't back up over more bytes than were returned by the last call"
       " to Next().";
  GOOGLE_CHECK_GE(count, 0)
    << " Parameter to BackUp() can't be negative.";

  backup_bytes_ = count;
}

bool CopyingInputStreamAdaptor::Skip(int count) {
  GOOGLE_CHECK_GE(count, 0);

  if (failed_) {
    // Already failed on a previous read.
    return false;
  }

  // First skip any bytes left over from a previous BackUp().
  if (backup_bytes_ >= count) {
    // We have more data left over than we're trying to skip.  Just chop it.
    backup_bytes_ -= count;
    return true;
  }

  count -= backup_bytes_;
  backup_bytes_ = 0;

  int skipped = copying_stream_->Skip(count);
  position_ += skipped;
  return skipped == count;
}

int64 CopyingInputStreamAdaptor::ByteCount() const {
  return position_ - backup_bytes_;
}

void CopyingInputStreamAdaptor::AllocateBufferIfNeeded() {
  if (buffer_.get() == NULL) {
    buffer_.reset(new uint8[buffer_size_]);
  }
}

void CopyingInputStreamAdaptor::FreeBuffer() {
  GOOGLE_CHECK_EQ(backup_bytes_, 0);
  buffer_used_ = 0;
  buffer_.reset();
}

// ===================================================================

CopyingOutputStream::~CopyingOutputStream() {}

CopyingOutputStreamAdaptor::CopyingOutputStreamAdaptor(
    CopyingOutputStream* copying_stream, int block_size)
  : copying_stream_(copying_stream),
    owns_copying_stream_(false),
    failed_(false),
    position_(0),
    buffer_size_(block_size > 0 ? block_size : kDefaultBlockSize),
    buffer_used_(0) {
}

CopyingOutputStreamAdaptor::~CopyingOutputStreamAdaptor() {
  WriteBuffer();
  if (owns_copying_stream_) {
    delete copying_stream_;
  }
}

bool CopyingOutputStreamAdaptor::Flush() {
  return WriteBuffer();
}

bool CopyingOutputStreamAdaptor::Next(void** data, int* size) {
  if (buffer_used_ == buffer_size_) {
    if (!WriteBuffer()) return false;
  }

  AllocateBufferIfNeeded();

  *data = buffer_.get() + buffer_used_;
  *size = buffer_size_ - buffer_used_;
  buffer_used_ = buffer_size_;
  return true;
}

void CopyingOutputStreamAdaptor::BackUp(int count) {
  GOOGLE_CHECK_GE(count, 0);
  GOOGLE_CHECK_EQ(buffer_used_, buffer_size_)
    << " BackUp() can only be called after Next().";
  GOOGLE_CHECK_LE(count, buffer_used_)
    << " Can't back up over more bytes than were returned by the last call"
       " to Next().";

  buffer_used_ -= count;
}

int64 CopyingOutputStreamAdaptor::ByteCount() const {
  return position_ + buffer_used_;
}

bool CopyingOutputStreamAdaptor::WriteBuffer() {
  if (failed_) {
    // Already failed on a previous write.
    return false;
  }

  if (buffer_used_ == 0) return true;

  if (copying_stream_->Write(buffer_.get(), buffer_used_)) {
    position_ += buffer_used_;
    buffer_used_ = 0;
    return true;
  } else {
    failed_ = true;
    FreeBuffer();
    return false;
  }
}

void CopyingOutputStreamAdaptor::AllocateBufferIfNeeded() {
  if (buffer_ == NULL) {
    buffer_.reset(new uint8[buffer_size_]);
  }
}

void CopyingOutputStreamAdaptor::FreeBuffer() {
  buffer_used_ = 0;
  buffer_.reset();
}

// ===================================================================

}  // namespace io
}  // namespace protobuf
}  // namespace google
