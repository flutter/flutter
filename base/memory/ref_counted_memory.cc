// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/memory/ref_counted_memory.h"

#include <stdlib.h>

#include "base/logging.h"

namespace base {

bool RefCountedMemory::Equals(
    const scoped_refptr<RefCountedMemory>& other) const {
  return other.get() &&
         size() == other->size() &&
         (memcmp(front(), other->front(), size()) == 0);
}

RefCountedMemory::RefCountedMemory() {}

RefCountedMemory::~RefCountedMemory() {}

const unsigned char* RefCountedStaticMemory::front() const {
  return data_;
}

size_t RefCountedStaticMemory::size() const {
  return length_;
}

RefCountedStaticMemory::~RefCountedStaticMemory() {}

RefCountedBytes::RefCountedBytes() {}

RefCountedBytes::RefCountedBytes(const std::vector<unsigned char>& initializer)
    : data_(initializer) {
}

RefCountedBytes::RefCountedBytes(const unsigned char* p, size_t size)
    : data_(p, p + size) {}

RefCountedBytes* RefCountedBytes::TakeVector(
    std::vector<unsigned char>* to_destroy) {
  RefCountedBytes* bytes = new RefCountedBytes;
  bytes->data_.swap(*to_destroy);
  return bytes;
}

const unsigned char* RefCountedBytes::front() const {
  // STL will assert if we do front() on an empty vector, but calling code
  // expects a NULL.
  return size() ? &data_.front() : NULL;
}

size_t RefCountedBytes::size() const {
  return data_.size();
}

RefCountedBytes::~RefCountedBytes() {}

RefCountedString::RefCountedString() {}

RefCountedString::~RefCountedString() {}

// static
RefCountedString* RefCountedString::TakeString(std::string* to_destroy) {
  RefCountedString* self = new RefCountedString;
  to_destroy->swap(self->data_);
  return self;
}

const unsigned char* RefCountedString::front() const {
  return data_.empty() ? NULL :
         reinterpret_cast<const unsigned char*>(data_.data());
}

size_t RefCountedString::size() const {
  return data_.size();
}

RefCountedMallocedMemory::RefCountedMallocedMemory(
    void* data, size_t length)
    : data_(reinterpret_cast<unsigned char*>(data)), length_(length) {
  DCHECK(data || length == 0);
}

const unsigned char* RefCountedMallocedMemory::front() const {
  return length_ ? data_ : NULL;
}

size_t RefCountedMallocedMemory::size() const {
  return length_;
}

RefCountedMallocedMemory::~RefCountedMallocedMemory() {
  free(data_);
}

}  //  namespace base
