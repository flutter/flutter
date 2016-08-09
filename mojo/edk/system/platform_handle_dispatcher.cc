// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/platform_handle_dispatcher.h"

#include <algorithm>
#include <utility>

#include "base/logging.h"

using mojo::platform::ScopedPlatformHandle;
using mojo::util::MutexLocker;
using mojo::util::RefPtr;

namespace mojo {
namespace system {

namespace {

const size_t kInvalidPlatformHandleIndex = static_cast<size_t>(-1);

struct SerializedPlatformHandleDispatcher {
  size_t platform_handle_index;  // (Or |kInvalidPlatformHandleIndex|.)
};

}  // namespace

// static
constexpr MojoHandleRights PlatformHandleDispatcher::kDefaultHandleRights;

ScopedPlatformHandle PlatformHandleDispatcher::PassPlatformHandle() {
  MutexLocker locker(&mutex());
  return platform_handle_.Pass();
}

Dispatcher::Type PlatformHandleDispatcher::GetType() const {
  return Type::PLATFORM_HANDLE;
}

bool PlatformHandleDispatcher::SupportsEntrypointClass(
    EntrypointClass entrypoint_class) const {
  return (entrypoint_class == EntrypointClass::NONE);
}

// static
RefPtr<PlatformHandleDispatcher> PlatformHandleDispatcher::Deserialize(
    Channel* channel,
    const void* source,
    size_t size,
    std::vector<ScopedPlatformHandle>* platform_handles) {
  if (size != sizeof(SerializedPlatformHandleDispatcher)) {
    LOG(ERROR) << "Invalid serialized platform handle dispatcher (bad size)";
    return nullptr;
  }

  const SerializedPlatformHandleDispatcher* serialization =
      static_cast<const SerializedPlatformHandleDispatcher*>(source);
  size_t platform_handle_index = serialization->platform_handle_index;

  // Starts off invalid, which is what we want.
  ScopedPlatformHandle platform_handle;

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

  return Create(std::move(platform_handle));
}

PlatformHandleDispatcher::PlatformHandleDispatcher(
    ScopedPlatformHandle platform_handle)
    : platform_handle_(platform_handle.Pass()) {}

PlatformHandleDispatcher::~PlatformHandleDispatcher() {}

void PlatformHandleDispatcher::CloseImplNoLock() {
  mutex().AssertHeld();
  platform_handle_.reset();
}

RefPtr<Dispatcher>
PlatformHandleDispatcher::CreateEquivalentDispatcherAndCloseImplNoLock(
    MessagePipe* /*message_pipe*/,
    unsigned /*port*/) {
  mutex().AssertHeld();
  CancelAllStateNoLock();
  return Create(platform_handle_.Pass());
}

void PlatformHandleDispatcher::StartSerializeImplNoLock(
    Channel* /*channel*/,
    size_t* max_size,
    size_t* max_platform_handles) {
  AssertHasOneRef();  // Only one ref => no need to take the lock.
  *max_size = sizeof(SerializedPlatformHandleDispatcher);
  *max_platform_handles = 1;
}

bool PlatformHandleDispatcher::EndSerializeAndCloseImplNoLock(
    Channel* /*channel*/,
    void* destination,
    size_t* actual_size,
    std::vector<ScopedPlatformHandle>* platform_handles) {
  AssertHasOneRef();  // Only one ref => no need to take the lock.

  SerializedPlatformHandleDispatcher* serialization =
      static_cast<SerializedPlatformHandleDispatcher*>(destination);
  if (platform_handle_.is_valid()) {
    serialization->platform_handle_index = platform_handles->size();
    platform_handles->push_back(std::move(platform_handle_));
  } else {
    serialization->platform_handle_index = kInvalidPlatformHandleIndex;
  }

  *actual_size = sizeof(SerializedPlatformHandleDispatcher);
  return true;
}

}  // namespace system
}  // namespace mojo
