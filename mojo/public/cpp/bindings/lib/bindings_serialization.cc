// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/bindings/lib/bindings_serialization.h"

#include "mojo/public/cpp/environment/logging.h"

namespace mojo {
namespace internal {

namespace {

const size_t kAlignment = 8;

template <typename T>
T AlignImpl(T t) {
  return t + (kAlignment - (t % kAlignment)) % kAlignment;
}

}  // namespace

size_t Align(size_t size) {
  return AlignImpl(size);
}

char* AlignPointer(char* ptr) {
  return reinterpret_cast<char*>(AlignImpl(reinterpret_cast<uintptr_t>(ptr)));
}

bool IsAligned(const void* ptr) {
  return !(reinterpret_cast<uintptr_t>(ptr) % kAlignment);
}

void EncodePointer(const void* ptr, uint64_t* offset) {
  if (!ptr) {
    *offset = 0;
    return;
  }

  const char* p_obj = reinterpret_cast<const char*>(ptr);
  const char* p_slot = reinterpret_cast<const char*>(offset);
  MOJO_DCHECK(p_obj > p_slot);

  *offset = static_cast<uint64_t>(p_obj - p_slot);
}

const void* DecodePointerRaw(const uint64_t* offset) {
  if (!*offset)
    return nullptr;
  return reinterpret_cast<const char*>(offset) + *offset;
}

void EncodeHandle(Handle* handle, std::vector<Handle>* handles) {
  if (handle->is_valid()) {
    handles->push_back(*handle);
    handle->set_value(static_cast<MojoHandle>(handles->size() - 1));
  } else {
    handle->set_value(kEncodedInvalidHandleValue);
  }
}

void EncodeHandle(Interface_Data* data, std::vector<Handle>* handles) {
  EncodeHandle(&data->handle, handles);
}

void EncodeHandle(MojoHandle* handle, std::vector<Handle>* handles) {
  EncodeHandle(reinterpret_cast<Handle*>(handle), handles);
}

void DecodeHandle(Handle* handle, std::vector<Handle>* handles) {
  if (handle->value() == kEncodedInvalidHandleValue) {
    *handle = Handle();
    return;
  }
  MOJO_DCHECK(handle->value() < handles->size());
  // Just leave holes in the vector so we don't screw up other indices.
  *handle = FetchAndReset(&handles->at(handle->value()));
}

void DecodeHandle(Interface_Data* data, std::vector<Handle>* handles) {
  DecodeHandle(&data->handle, handles);
}

void DecodeHandle(MojoHandle* handle, std::vector<Handle>* handles) {
  DecodeHandle(reinterpret_cast<Handle*>(handle), handles);
}

}  // namespace internal
}  // namespace mojo
