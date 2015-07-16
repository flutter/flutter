// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/simple_platform_shared_buffer.h"

#include "base/logging.h"
#include "mojo/edk/embedder/platform_handle_utils.h"

namespace mojo {
namespace embedder {

// static
SimplePlatformSharedBuffer* SimplePlatformSharedBuffer::Create(
    size_t num_bytes) {
  DCHECK_GT(num_bytes, 0u);

  SimplePlatformSharedBuffer* rv = new SimplePlatformSharedBuffer(num_bytes);
  if (!rv->Init()) {
    // We can't just delete it directly, due to the "in destructor" (debug)
    // check.
    scoped_refptr<SimplePlatformSharedBuffer> deleter(rv);
    return nullptr;
  }

  return rv;
}

// static
SimplePlatformSharedBuffer*
SimplePlatformSharedBuffer::CreateFromPlatformHandle(
    size_t num_bytes,
    ScopedPlatformHandle platform_handle) {
  DCHECK_GT(num_bytes, 0u);

  SimplePlatformSharedBuffer* rv = new SimplePlatformSharedBuffer(num_bytes);
  if (!rv->InitFromPlatformHandle(platform_handle.Pass())) {
    // We can't just delete it directly, due to the "in destructor" (debug)
    // check.
    scoped_refptr<SimplePlatformSharedBuffer> deleter(rv);
    return nullptr;
  }

  return rv;
}

size_t SimplePlatformSharedBuffer::GetNumBytes() const {
  return num_bytes_;
}

scoped_ptr<PlatformSharedBufferMapping> SimplePlatformSharedBuffer::Map(
    size_t offset,
    size_t length) {
  if (!IsValidMap(offset, length))
    return nullptr;

  return MapNoCheck(offset, length);
}

bool SimplePlatformSharedBuffer::IsValidMap(size_t offset, size_t length) {
  if (offset > num_bytes_ || length == 0)
    return false;

  // Note: This is an overflow-safe check of |offset + length > num_bytes_|
  // (that |num_bytes >= offset| is verified above).
  if (length > num_bytes_ - offset)
    return false;

  return true;
}

scoped_ptr<PlatformSharedBufferMapping> SimplePlatformSharedBuffer::MapNoCheck(
    size_t offset,
    size_t length) {
  DCHECK(IsValidMap(offset, length));
  return MapImpl(offset, length);
}

ScopedPlatformHandle SimplePlatformSharedBuffer::DuplicatePlatformHandle() {
  return mojo::embedder::DuplicatePlatformHandle(handle_.get());
}

ScopedPlatformHandle SimplePlatformSharedBuffer::PassPlatformHandle() {
  DCHECK(HasOneRef());
  return handle_.Pass();
}

SimplePlatformSharedBuffer::SimplePlatformSharedBuffer(size_t num_bytes)
    : num_bytes_(num_bytes) {
}

SimplePlatformSharedBuffer::~SimplePlatformSharedBuffer() {
}

SimplePlatformSharedBufferMapping::~SimplePlatformSharedBufferMapping() {
  Unmap();
}

void* SimplePlatformSharedBufferMapping::GetBase() const {
  return base_;
}

size_t SimplePlatformSharedBufferMapping::GetLength() const {
  return length_;
}

}  // namespace embedder
}  // namespace mojo
