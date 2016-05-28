// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/embedder.h"

#include "base/logging.h"
#include "mojo/edk/embedder/embedder_internal.h"
#include "mojo/edk/system/configuration.h"
#include "mojo/edk/system/core.h"
#include "mojo/edk/system/handle.h"
#include "mojo/edk/system/platform_handle_dispatcher.h"
#include "mojo/edk/util/ref_ptr.h"

using mojo::platform::ScopedPlatformHandle;
using mojo::util::RefPtr;

namespace mojo {
namespace embedder {

namespace internal {

// Declared in embedder_internal.h.
PlatformSupport* g_platform_support = nullptr;
system::Core* g_core = nullptr;

}  // namespace internal

Configuration* GetConfiguration() {
  return system::GetMutableConfiguration();
}

void Init(std::unique_ptr<PlatformSupport> platform_support) {
  DCHECK(platform_support);

  DCHECK(!internal::g_platform_support);
  internal::g_platform_support = platform_support.release();

  DCHECK(!internal::g_core);
  internal::g_core = new system::Core(internal::g_platform_support);
}

MojoResult AsyncWait(MojoHandle handle,
                     MojoHandleSignals signals,
                     const std::function<void(MojoResult)>& callback) {
  return internal::g_core->AsyncWait(handle, signals, callback);
}

MojoResult CreatePlatformHandleWrapper(
    ScopedPlatformHandle platform_handle,
    MojoHandle* platform_handle_wrapper_handle) {
  DCHECK(platform_handle_wrapper_handle);

  auto dispatcher =
      system::PlatformHandleDispatcher::Create(platform_handle.Pass());

  DCHECK(internal::g_core);
  MojoHandle h = internal::g_core->AddHandle(
      system::Handle(dispatcher.Clone(),
                     system::PlatformHandleDispatcher::kDefaultHandleRights));
  if (h == MOJO_HANDLE_INVALID) {
    LOG(ERROR) << "Handle table full";
    dispatcher->Close();
    return MOJO_RESULT_RESOURCE_EXHAUSTED;
  }

  *platform_handle_wrapper_handle = h;
  return MOJO_RESULT_OK;
}

MojoResult PassWrappedPlatformHandle(MojoHandle platform_handle_wrapper_handle,
                                     ScopedPlatformHandle* platform_handle) {
  DCHECK(platform_handle);

  DCHECK(internal::g_core);
  system::Handle h;
  MojoResult result =
      internal::g_core->GetHandle(platform_handle_wrapper_handle, &h);
  if (result != MOJO_RESULT_OK)
    return result;

  if (h.dispatcher->GetType() != system::Dispatcher::Type::PLATFORM_HANDLE)
    return MOJO_RESULT_INVALID_ARGUMENT;

  if (!h.has_all_rights(MOJO_HANDLE_RIGHT_READ | MOJO_HANDLE_RIGHT_WRITE))
    return MOJO_RESULT_PERMISSION_DENIED;

  *platform_handle =
      static_cast<system::PlatformHandleDispatcher*>(h.dispatcher.get())
          ->PassPlatformHandle();
  return MOJO_RESULT_OK;
}

}  // namespace embedder
}  // namespace mojo
