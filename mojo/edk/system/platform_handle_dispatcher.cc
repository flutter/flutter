// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/platform_handle_dispatcher.h"

#include <algorithm>

#include "base/logging.h"

namespace mojo {
namespace system {

namespace {

const size_t kInvalidPlatformHandleIndex = static_cast<size_t>(-1);

struct SerializedPlatformHandleDispatcher {
  size_t platform_handle_index;  // (Or |kInvalidPlatformHandleIndex|.)
};

}  // namespace

embedder::ScopedPlatformHandle PlatformHandleDispatcher::PassPlatformHandle() {
  MutexLocker locker(&mutex());
  return platform_handle_.Pass();
}

Dispatcher::Type PlatformHandleDispatcher::GetType() const {
  return Type::PLATFORM_HANDLE;
}

// static
scoped_refptr<PlatformHandleDispatcher> PlatformHandleDispatcher::Deserialize(
    Channel* channel,
    const void* source,
    size_t size,
    embedder::PlatformHandleVector* platform_handles) {
  if (size != sizeof(SerializedPlatformHandleDispatcher)) {
    LOG(ERROR) << "Invalid serialized platform handle dispatcher (bad size)";
    return nullptr;
  }

  const SerializedPlatformHandleDispatcher* serialization =
      static_cast<const SerializedPlatformHandleDispatcher*>(source);
  size_t platform_handle_index = serialization->platform_handle_index;

  // Starts off invalid, which is what we want.
  embedder::PlatformHandle platform_handle;

  if (platform_handle_index != kInvalidPlatformHandleIndex) {
    if (!platform_handles ||
        platform_handle_index >= platform_handles->size()) {
      LOG(ERROR)
          << "Invalid serialized platform handle dispatcher (missing handles)";
      return nullptr;
    }

    // We take ownership of the handle, so we have to invalidate the one in
    // |platform_handles|.
    std::swap(platform_handle, (*platform_handles)[platform_handle_index]);
  }

  return Create(embedder::ScopedPlatformHandle(platform_handle));
}

PlatformHandleDispatcher::PlatformHandleDispatcher(
    embedder::ScopedPlatformHandle platform_handle)
    : platform_handle_(platform_handle.Pass()) {
}

PlatformHandleDispatcher::~PlatformHandleDispatcher() {
}

void PlatformHandleDispatcher::CloseImplNoLock() {
  mutex().AssertHeld();
  platform_handle_.reset();
}

scoped_refptr<Dispatcher>
PlatformHandleDispatcher::CreateEquivalentDispatcherAndCloseImplNoLock() {
  mutex().AssertHeld();
  return Create(platform_handle_.Pass());
}

void PlatformHandleDispatcher::StartSerializeImplNoLock(
    Channel* /*channel*/,
    size_t* max_size,
    size_t* max_platform_handles) {
  DCHECK(HasOneRef());  // Only one ref => no need to take the lock.
  *max_size = sizeof(SerializedPlatformHandleDispatcher);
  *max_platform_handles = 1;
}

bool PlatformHandleDispatcher::EndSerializeAndCloseImplNoLock(
    Channel* /*channel*/,
    void* destination,
    size_t* actual_size,
    embedder::PlatformHandleVector* platform_handles) {
  DCHECK(HasOneRef());  // Only one ref => no need to take the lock.

  SerializedPlatformHandleDispatcher* serialization =
      static_cast<SerializedPlatformHandleDispatcher*>(destination);
  if (platform_handle_.is_valid()) {
    serialization->platform_handle_index = platform_handles->size();
    platform_handles->push_back(platform_handle_.release());
  } else {
    serialization->platform_handle_index = kInvalidPlatformHandleIndex;
  }

  *actual_size = sizeof(SerializedPlatformHandleDispatcher);
  return true;
}

}  // namespace system
}  // namespace mojo
