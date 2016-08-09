// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_PLATFORM_HANDLE_DISPATCHER_H_
#define MOJO_EDK_SYSTEM_PLATFORM_HANDLE_DISPATCHER_H_

#include <vector>

#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/system/simple_dispatcher.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

// A dispatcher that simply wraps/transports a |PlatformHandle| (only for use by
// the embedder).
class PlatformHandleDispatcher final : public SimpleDispatcher {
 public:
  // The default/standard rights for a platform handle (wrapper) handle.
  static constexpr MojoHandleRights kDefaultHandleRights =
      MOJO_HANDLE_RIGHT_TRANSFER | MOJO_HANDLE_RIGHT_READ |
      MOJO_HANDLE_RIGHT_WRITE;

  static util::RefPtr<PlatformHandleDispatcher> Create(
      platform::ScopedPlatformHandle platform_handle) {
    return AdoptRef(new PlatformHandleDispatcher(platform_handle.Pass()));
  }

  platform::ScopedPlatformHandle PassPlatformHandle();

  // |Dispatcher| public methods:
  Type GetType() const override;
  bool SupportsEntrypointClass(EntrypointClass entrypoint_class) const override;

  // The "opposite" of |SerializeAndClose()|. (Typically this is called by
  // |Dispatcher::Deserialize()|.)
  static util::RefPtr<PlatformHandleDispatcher> Deserialize(
      Channel* channel,
      const void* source,
      size_t size,
      std::vector<platform::ScopedPlatformHandle>* platform_handles);

 private:
  explicit PlatformHandleDispatcher(
      platform::ScopedPlatformHandle platform_handle);
  ~PlatformHandleDispatcher() override;

  // |Dispatcher| protected methods:
  void CloseImplNoLock() override;
  util::RefPtr<Dispatcher> CreateEquivalentDispatcherAndCloseImplNoLock(
      MessagePipe* message_pipe,
      unsigned port) override;
  void StartSerializeImplNoLock(Channel* channel,
                                size_t* max_size,
                                size_t* max_platform_handles) override
      MOJO_NOT_THREAD_SAFE;
  bool EndSerializeAndCloseImplNoLock(
      Channel* channel,
      void* destination,
      size_t* actual_size,
      std::vector<platform::ScopedPlatformHandle>* platform_handles) override
      MOJO_NOT_THREAD_SAFE;

  platform::ScopedPlatformHandle platform_handle_ MOJO_GUARDED_BY(mutex());

  MOJO_DISALLOW_COPY_AND_ASSIGN(PlatformHandleDispatcher);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_PLATFORM_HANDLE_DISPATCHER_H_
